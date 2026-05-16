import 'package:flutter/material.dart';

/// Design tokens shared across all four themes.
/// Source of truth: claude.design handoff in vLearn2Spec/.
class AppTokens {
  AppTokens._();

  // ─── Spacing scale (4pt grid) ─────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  // ─── Border radius ────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ─── Elevation / shadow ───────────────────────────────
  static List<BoxShadow> shadowSm(Color seed) => [
        BoxShadow(
          color: seed.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMd(Color seed) => [
        BoxShadow(
          color: seed.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Animation durations ──────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
}

/// Per-theme color palette. One palette per theme key.
class AppPalette {
  const AppPalette({
    required this.key,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.outline,
    required this.success,
    required this.warning,
    required this.error,
  });

  final String key;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color outline;
  final Color success;
  final Color warning;
  final Color error;

  static const apricot = AppPalette(
    key: 'apricot',
    primary: Color(0xFFFF6B47),
    primaryDark: Color(0xFFE54D2A),
    accent: Color(0xFFFFB997),
    background: Color(0xFFFFF8F4),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFFFEFE5),
    onSurface: Color(0xFF1B1B1F),
    onSurfaceMuted: Color(0xFF6B6B72),
    outline: Color(0xFFE8E0D9),
    success: Color(0xFF5DBE9C),
    warning: Color(0xFFFFB44C),
    error: Color(0xFFE5484D),
  );

  static const sage = AppPalette(
    key: 'sage',
    primary: Color(0xFF5DBE9C),
    primaryDark: Color(0xFF3FA37D),
    accent: Color(0xFFA8E6CF),
    background: Color(0xFFF4FAF7),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE3F1EB),
    onSurface: Color(0xFF1B1F1D),
    onSurfaceMuted: Color(0xFF626B66),
    outline: Color(0xFFD9E8E1),
    success: Color(0xFF5DBE9C),
    warning: Color(0xFFFFB44C),
    error: Color(0xFFE5484D),
  );

  static const iris = AppPalette(
    key: 'iris',
    primary: Color(0xFF7C6BE6),
    primaryDark: Color(0xFF5B4ECF),
    accent: Color(0xFFC9B6FF),
    background: Color(0xFFF6F5FF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEFEAFF),
    onSurface: Color(0xFF1B1A24),
    onSurfaceMuted: Color(0xFF6B6878),
    outline: Color(0xFFE2DEEF),
    success: Color(0xFF5DBE9C),
    warning: Color(0xFFFFB44C),
    error: Color(0xFFE5484D),
  );

  static const obsidian = AppPalette(
    key: 'obsidian',
    primary: Color(0xFF4F4C7E),
    primaryDark: Color(0xFF2C2A4A),
    accent: Color(0xFF9D99C7),
    background: Color(0xFF121120),
    surface: Color(0xFF1E1C2E),
    surfaceVariant: Color(0xFF26243A),
    onSurface: Color(0xFFEFEEF5),
    onSurfaceMuted: Color(0xFFA8A6B8),
    outline: Color(0xFF38364E),
    success: Color(0xFF5DBE9C),
    warning: Color(0xFFFFB44C),
    error: Color(0xFFFF7177),
  );

  static const Map<String, AppPalette> byKey = {
    'apricot': apricot,
    'sage': sage,
    'iris': iris,
    'obsidian': obsidian,
  };
}
