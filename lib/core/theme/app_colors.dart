import 'package:flutter/material.dart';

class AppColors {
  static const Color bg         = Color(0xFF060818);
  static const Color bgCard     = Color(0xFF0D1225);
  static const Color bgSurface  = Color(0xFF111827);
  static const Color bgGlass    = Color(0x1AFFFFFF);

  static const LinearGradient primaryGrad = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
  static const LinearGradient warningGrad = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFEF4444)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
  static const LinearGradient successGrad = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
  static const LinearGradient goldGrad = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const Color neonPurple  = Color(0xFF7C3AED);
  static const Color neonBlue    = Color(0xFF2563EB);
  static const Color neonCyan    = Color(0xFF06B6D4);
  static const Color neonGreen   = Color(0xFF10B981);
  static const Color neonOrange  = Color(0xFFFF6B35);
  static const Color neonRed     = Color(0xFFEF4444);
  static const Color neonGold    = Color(0xFFF59E0B);

  static const Color textPrimary   = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF475569);

  static const Color border      = Color(0x33FFFFFF);
  static const Color borderGlow  = Color(0x667C3AED);
}
