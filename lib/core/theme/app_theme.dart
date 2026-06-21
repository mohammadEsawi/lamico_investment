import 'package:flutter/material.dart';

// ── Palette ──────────────────────────────────────────────────────────────────

class Palette {
  // Backgrounds
  final Color bg;
  final Color bgCard;
  final Color bgSurface;
  final Color bgGlass;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Border
  final Color border;

  // Brightness
  final Brightness brightness;

  const Palette({
    required this.bg,
    required this.bgCard,
    required this.bgSurface,
    required this.bgGlass,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.brightness,
  });
}

// ── Dark Palette ──────────────────────────────────────────────────────────────

const darkPalette = Palette(
  bg         : Color(0xFF0F172A),
  bgCard     : Color(0xFF1E293B),
  bgSurface  : Color(0xFF334155),
  bgGlass    : Color(0x14FFFFFF),
  textPrimary  : Color(0xFFF8FAFC),
  textSecondary: Color(0xFF94A3B8),
  textMuted    : Color(0xFF64748B),
  border       : Color(0x22FFFFFF),
  brightness   : Brightness.dark,
);

// ── Light Palette ─────────────────────────────────────────────────────────────

const lightPalette = Palette(
  bg         : Color(0xFFF7F4EE),
  bgCard     : Color(0xFFFFFFFF),
  bgSurface  : Color(0xFFEEEAE0),
  bgGlass    : Color(0x0A000000),
  textPrimary  : Color(0xFF1A1F2E),
  textSecondary: Color(0xFF4A5568),
  textMuted    : Color(0xFF94A3B8),
  border       : Color(0x18000000),
  brightness   : Brightness.light,
);

// ── Accent Colors (same for both modes) ───────────────────────────────────────

class Accent {
  static const Color purple = Color(0xFF7C3AED);
  static const Color blue   = Color(0xFF2563EB);
  static const Color cyan   = Color(0xFF06B6D4);
  static const Color green  = Color(0xFF10B981);
  static const Color orange = Color(0xFFFF6B35);
  static const Color red    = Color(0xFFEF4444);
  static const Color gold   = Color(0xFFF59E0B);

  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    begin: Alignment.topRight, end: Alignment.bottomLeft,
  );
  static const LinearGradient successGrad = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
    begin: Alignment.topRight, end: Alignment.bottomLeft,
  );
  static const LinearGradient warningGrad = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFEF4444)],
    begin: Alignment.topRight, end: Alignment.bottomLeft,
  );
  static const LinearGradient goldGrad = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topRight, end: Alignment.bottomLeft,
  );
}

// ── Context Extension ─────────────────────────────────────────────────────────

extension AppThemeExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Palette get colors => isDark ? darkPalette : lightPalette;
}

// ── ThemeData builders ────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData build(Palette p) => ThemeData(
    fontFamily: 'Cairo',
    brightness: p.brightness,
    scaffoldBackgroundColor: p.bg,
    cardColor: p.bgCard,
    colorScheme: ColorScheme(
      brightness    : p.brightness,
      primary       : Accent.purple,
      onPrimary     : Colors.white,
      secondary     : Accent.cyan,
      onSecondary   : Colors.white,
      error         : Accent.red,
      onError       : Colors.white,
      surface       : p.bgCard,
      onSurface     : p.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Accent.blue,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E3A8A),
      indicatorColor: Colors.white.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      elevation: 8,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? Colors.white : const Color(0xFFBFD4FF),
          size: selected ? 26 : 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          color: selected ? Colors.white : const Color(0xFFBFD4FF),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        );
      }),
    ),
    dividerColor: p.border,
    useMaterial3: true,
  );

  static final dark  = build(darkPalette);
  static final light = build(lightPalette);
}
