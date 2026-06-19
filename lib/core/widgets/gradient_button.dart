import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final LinearGradient gradient;
  final bool isLoading;
  final double height;

  const GradientButton({
    required this.label,
    this.onTap,
    this.gradient = AppColors.primaryGrad,
    this.isLoading = false,
    this.height = 52,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: AppText.h3.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
}
