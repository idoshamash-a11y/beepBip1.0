import 'package:flutter/material.dart';

/// Fallback if neither `dart:html` nor `dart:io` map path is used (should not
/// occur in normal Flutter targets).
class GlobeMapEmbed extends StatelessWidget {
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
  final dynamic center;
  final bool isDark;
  final String honeyBase64;
  final String pinsBase64;
  final dynamic userLocation;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFF0D0D0D));
  }
}
