import 'package:flutter/material.dart';

class AppColors {
  static const Color bg         = Color(0xFFF7F4EE);
  static const Color bgCard     = Color(0xFFFFFFFF);
  static const Color bgSurface  = Color(0xFFEEEAE0);
  static const Color bgGlass    = Color(0x0A000000);

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
  static const Color neonBlue    = Color(0xFF1E3A8A);
  static const Color neonCyan    = Color(0xFF0891B2);
  static const Color neonGreen   = Color(0xFF059669);
  static const Color neonOrange  = Color(0xFFEA580C);
  static const Color neonRed     = Color(0xFFDC2626);
  static const Color neonGold    = Color(0xFFD97706);

  static const Color textPrimary   = Color(0xFF1A1F2E);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted     = Color(0xFF94A3B8);

  static const Color border      = Color(0x18000000);
  static const Color borderGlow  = Color(0x447C3AED);

  static const Color navBar      = Color(0xFF1E3A8A);
}
