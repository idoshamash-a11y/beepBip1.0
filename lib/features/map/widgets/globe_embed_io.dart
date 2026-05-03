import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'globe_map_html.dart';

/// MapLibre GL globe (MapTiler) in a [WebView] — iOS / Android (and other
/// `dart:io` targets). Map screen only builds this on phone + tablet.
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
  WebViewController? _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    final ctrl = WebViewController();
    _controller = ctrl;
    ctrl
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D0D0D))
      ..addJavaScriptChannel(
        'Beepbip',
        onMessageReceived: (_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _patchJs(ctrl);
        },
      )
      ..loadHtmlString(
        _html(),
        baseUrl: 'https://api.maptiler.com',
      );
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
  void didUpdateWidget(covariant GlobeMapEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _controller;
    if (c == null) return;

    if (oldWidget.mapTilerKey != widget.mapTilerKey ||
        oldWidget.isDark != widget.isDark) {
      setState(() => _ready = false);
      c.loadHtmlString(
        _html(),
        baseUrl: 'https://api.maptiler.com',
      );
      return;
    }

    if (!_ready) return;
    _patchJs(c);
  }

  void _patchJs(WebViewController c) {
    final u = widget.userLocation;
    c.runJavaScript(
      'window.beepbipPatch(${jsonEncode(widget.honeyBase64)}, '
      '${jsonEncode(widget.pinsBase64)}, ${u != null}, '
      '${u?.latitude ?? 0}, ${u?.longitude ?? 0});',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) return const SizedBox.expand();
    return ColoredBox(
      color: const Color(0xFF0D0D0D),
      child: WebViewWidget(controller: c),
    );
  }
}
