import 'dart:convert';

/// MapLibre GL JS (globe + honeycomb + pins) embedded in WebView / iframe.
///
/// MapTiler style URL uses the same key as the rest of the app.
/// The inline script waits until `maplibregl` exists — external scripts can load
/// slightly after parse on some WebView/iframe paths.
String buildGlobeMapHtml({
  required String mapTilerKey,
  required String styleId,
  required double centerLat,
  required double centerLng,
  required String honeyBase64,
  required String pinsBase64,
  required bool hasUser,
  required double userLat,
  required double userLng,
}) {
  const accent = '#ff8c1a';
  final keyJs = jsonEncode(mapTilerKey);
  final honeyJs = jsonEncode(honeyBase64);
  final pinsJs = jsonEncode(pinsBase64);
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
  <link href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css" rel="stylesheet" />
  <style>
    html, body, #map { margin: 0; height: 100%; width: 100%; background: #0d0d0d; }
  </style>
</head>
<body>
  <div id="map"></div>
  <script src="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js"></script>
  <script>
(function() {
  function boot() {
    if (typeof maplibregl === 'undefined') {
      setTimeout(boot, 20);
      return;
    }
    try {
      const KEY = $keyJs;
      const styleUrl = 'https://api.maptiler.com/maps/$styleId/style.json?key=' + encodeURIComponent(KEY);
      const map = new maplibregl.Map({
        container: 'map',
        style: styleUrl,
        center: [$centerLng, $centerLat],
        zoom: 5.2,
        pitch: 50,
        bearing: -12,
        maxPitch: 85,
        attributionControl: true
      });
      map.addControl(new maplibregl.NavigationControl(), 'top-right');

      function applyHoneyFromB64(b64) {
        if (!b64 || b64.length < 4) return;
        try {
          const gj = JSON.parse(atob(b64));
          map.getSource('honeycomb').setData(gj);
        } catch (e) {}
      }
      function applyPinsFromB64(b64) {
        if (!b64 || b64.length < 4) return;
        try {
          const gj = JSON.parse(atob(b64));
          map.getSource('pins').setData(gj);
        } catch (e) {}
      }
      function applyUser(has, lat, lng) {
        if (!has) {
          map.getSource('me').setData({ type: 'FeatureCollection', features: [] });
          return;
        }
        map.getSource('me').setData({
          type: 'FeatureCollection',
          features: [{
            type: 'Feature',
            properties: {},
            geometry: { type: 'Point', coordinates: [lng, lat] }
          }]
        });
      }

      window.beepbipPatch = function(hB64, pB64, hasUser, uLat, uLng) {
        applyHoneyFromB64(hB64);
        applyPinsFromB64(pB64);
        applyUser(!!hasUser, uLat, uLng);
      };

      map.on('load', function() {
        try { map.setProjection({ type: 'globe' }); } catch (e) {}

        map.setFog({
          color: 'rgb(18, 22, 40)',
          'horizon-blend': 0.14,
          'space-color': 'rgb(8, 10, 22)',
          'star-intensity': 0.45
        });

        map.addSource('honeycomb', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        });
        map.addLayer({
          id: 'honey-fill',
          type: 'fill',
          source: 'honeycomb',
          paint: {
            'fill-color': '$accent',
            'fill-opacity': 0.16
          }
        });
        map.addLayer({
          id: 'honey-line',
          type: 'line',
          source: 'honeycomb',
          paint: {
            'line-color': '$accent',
            'line-width': 1.3,
            'line-opacity': 0.55
          }
        });

        map.addSource('pins', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        });
        map.addLayer({
          id: 'pins-circle',
          type: 'circle',
          source: 'pins',
          paint: {
            'circle-radius': 16,
            'circle-color': '#ffffff',
            'circle-stroke-width': 2.5,
            'circle-stroke-color': '$accent'
          }
        });

        map.addSource('me', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: [] }
        });
        map.addLayer({
          id: 'me-dot',
          type: 'circle',
          source: 'me',
          paint: {
            'circle-radius': 11,
            'circle-color': '$accent',
            'circle-stroke-width': 3,
            'circle-stroke-color': '#ffffff'
          }
        });

        applyHoneyFromB64($honeyJs);
        applyPinsFromB64($pinsJs);
        applyUser(${hasUser ? 'true' : 'false'}, $userLat, $userLng);

        try {
          if (typeof Beepbip !== 'undefined' && Beepbip.postMessage) {
            Beepbip.postMessage('ready');
          }
        } catch (e) {}
      });

      map.on('error', function(e) { console.error('maplibre', e); });
    } catch (err) {
      console.error('beepbip globe boot', err);
    }
  }
  boot();
})();
  </script>
</body>
</html>
''';
}
