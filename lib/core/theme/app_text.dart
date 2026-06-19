import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  static const String font = 'Cairo';

  static const TextStyle hero = TextStyle(
    fontFamily: font, fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.3,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: font, fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: font, fontSize: 20, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: font, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: font, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: font, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
  static const TextStyle label = TextStyle(
    fontFamily: font, fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textMuted, letterSpacing: 0.8,
  );
}
