import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:h3_flutter/h3_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

/// Uber H3–based "beehive" neighborhood cells around a point.
///
/// Resolution 8 ≈ 460 m edge length — a good city-neighborhood grain.
/// Ring count scales roughly with the discovery [radiusKm] slider.
class NeighborhoodHoneycomb {
  NeighborhoodHoneycomb._();

  static H3? _h3;

  static H3 _h() => _h3 ??= const H3Factory().load();

  /// H3 resolution (0–15). 8 ≈ ~0.75 km² hex area (urban blocks).
  static const int defaultResolution = 8;

  /// Converts k-ring distance from the discovery radius (km).
  static int ringStepsForRadiusKm(double radiusKm) {
    return (radiusKm / 0.45).ceil().clamp(2, 12);
  }

  /// GeoJSON FeatureCollection of filled hex polygons for MapLibre / web globe.
  /// [maxCells] trims the k-ring output so HTML/WebView strings stay small.
  static Map<String, Object?> honeycombFeatureCollection({
    required LatLng center,
    required double radiusKm,
    int resolution = defaultResolution,
    int? maxCells,
  }) {
    final h3 = _h();
    final origin = h3.geoToH3(
      GeoCoord(lon: center.longitude, lat: center.latitude),
      resolution,
    );
    final k = ringStepsForRadiusKm(radiusKm);
    var cells = h3.kRing(origin, k);
    if (maxCells != null && cells.length > maxCells) {
      cells = cells.take(maxCells).toList();
    }
    final features = <Map<String, Object?>>[];
    for (final cell in cells) {
      final boundary = h3.h3ToGeoBoundary(cell);
      final ring = boundary
          .map((g) => <double>[g.lon, g.lat])
          .toList(growable: true);
      if (ring.isNotEmpty &&
          (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
        ring.add(List<double>.from(ring.first));
      }
      features.add({
        'type': 'Feature',
        'properties': <String, Object?>{},
        'geometry': {
          'type': 'Polygon',
          'coordinates': <Object>[ring],
        },
      });
    }
    return {
      'type': 'FeatureCollection',
      'features': features,
    };
  }

  static String honeycombGeoJsonBase64({
    required LatLng center,
    required double radiusKm,
    int resolution = defaultResolution,
    int? maxCells,
  }) {
    final fc = honeycombFeatureCollection(
      center: center,
      radiusKm: radiusKm,
      resolution: resolution,
      maxCells: maxCells,
    );
    return base64Encode(utf8.encode(jsonEncode(fc)));
  }

  /// Filled polygons for [flutter_map] (macOS / Windows / Linux fallback).
  static List<Polygon<Object>> flutterMapPolygons({
    required LatLng center,
    required double radiusKm,
    int resolution = defaultResolution,
  }) {
    final h3 = _h();
    final origin = h3.geoToH3(
      GeoCoord(lon: center.longitude, lat: center.latitude),
      resolution,
    );
    final k = ringStepsForRadiusKm(radiusKm);
    final cells = h3.kRing(origin, k);
    const accent = AppColors.accent;
    return cells.map((cell) {
      final boundary = h3.h3ToGeoBoundary(cell);
      final points =
          boundary.map((g) => LatLng(g.lat, g.lon)).toList(growable: false);
      return Polygon<Object>(
        points: points,
        color: accent.withValues(alpha: 0.11),
        borderColor: accent.withValues(alpha: 0.52),
        borderStrokeWidth: 1.4,
      );
    }).toList();
  }

  /// Point features for simple circle layers on the globe (nearby people).
  static Map<String, Object?> pinsFeatureCollection({
    required List<({double lat, double lng, String name})> pins,
  }) {
    return {
      'type': 'FeatureCollection',
      'features': pins
          .map(
            (p) => {
              'type': 'Feature',
              'properties': <String, Object?>{'name': p.name},
              'geometry': {
                'type': 'Point',
                'coordinates': <double>[p.lng, p.lat],
              },
            },
          )
          .toList(),
    };
  }

  static String pinsGeoJsonBase64({
    required List<({double lat, double lng, String name})> pins,
  }) {
    final fc = pinsFeatureCollection(pins: pins);
    return base64Encode(utf8.encode(jsonEncode(fc)));
  }
}
