import 'package:flutter/material.dart';

class AppColors {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color navBg;
  final Color navBorder;
  final Color inputBg;
  final Color overlay;

  const AppColors._({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.navBg,
    required this.navBorder,
    required this.inputBg,
    required this.overlay,
  });

  static const Color accent = Color(0xFFFF8C1A);
  static const Color accentDim = Color(0x1FFF8C1A);  // 12% opacity
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);

  static const AppColors dark = AppColors._(
    bg: Color(0xFF0D0D0D),
    surface: Color(0xFF141414),
    surface2: Color(0xFF1E1E1E),
    border: Color(0xFF2A2A2A),
    divider: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFF2F2F2),
    textSecondary: Color(0xFF6B6B6B),
    textMuted: Color(0xFF3A3A3A),
    navBg: Color(0xFF0D0D0D),
    navBorder: Color(0xFF1E1E1E),
    inputBg: Color(0xFF171717),
    overlay: Color(0xFF111111),
  );

  static const AppColors light = AppColors._(
    bg: Color(0xFFF7F7F7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2F2F2),
    border: Color(0xFFE8E8E8),
    divider: Color(0xFFF0F0F0),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF6B6B6B),
    textMuted: Color(0xFFCCCCCC),
    navBg: Color(0xFFFFFFFF),
    navBorder: Color(0xFFF0F0F0),
    inputBg: Color(0xFFF5F5F5),
    overlay: Color(0xFFFFFFFF),
  );
}

extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
