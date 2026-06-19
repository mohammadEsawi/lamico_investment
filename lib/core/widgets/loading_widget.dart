import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.neonPurple),
      );
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateWidget({
    this.message = 'لا توجد بيانات',
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, style: AppText.body),
          ],
        ),
      );
}
