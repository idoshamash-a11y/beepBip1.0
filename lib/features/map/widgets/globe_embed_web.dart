import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:web/web.dart' as web;

import 'globe_map_html.dart';

/// MapLibre GL globe in an iframe (`srcdoc`). Flutter web cannot use the
/// mobile WebView implementation; `HtmlElementView` embeds the same HTML.
///
/// Data updates: parent should supply a new [key] when honey/pins/user change
/// so the iframe is rebuilt (patching cross-frame is avoided).
class GlobeMapEmbed extends StatefulWidget {
  const GlobeMapEmbed({
    super.key,
    required this.mapTilerKey,
    required this.center,
    required this.isDark,
    required this.honeyBase64,
    required this.pinsBase64,
    this.userLocation,
  });

  final String mapTilerKey;
  final LatLng center;
  final bool isDark;
  final String honeyBase64;
  final String pinsBase64;
  final LatLng? userLocation;

  @override
  State<GlobeMapEmbed> createState() => _GlobeMapEmbedState();
}

class _GlobeMapEmbedState extends State<GlobeMapEmbed> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'beepbip-globe-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    final html = _html();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      iframe.setAttribute('srcdoc', html);
      return iframe;
    });
  }

  String _html() {
    final styleId =
        widget.isDark ? 'streets-v2-dark' : 'streets-v2-light';
    final u = widget.userLocation;
    return buildGlobeMapHtml(
      mapTilerKey: widget.mapTilerKey,
      styleId: styleId,
      centerLat: widget.center.latitude,
      centerLng: widget.center.longitude,
      honeyBase64: widget.honeyBase64,
      pinsBase64: widget.pinsBase64,
      hasUser: u != null,
      userLat: u?.latitude ?? 0,
      userLng: u?.longitude ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0D0D0D),
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
