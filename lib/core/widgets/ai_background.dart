import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AiBackground extends StatelessWidget {
  final Widget child;

  const AiBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.bg),
        Positioned(
          top: -100, left: -100,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.neonPurple.withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80, right: -80,
          child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.neonBlue.withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
