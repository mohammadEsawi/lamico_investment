import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AiBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_read_outlined,
                        color: AppColors.neonGreen, size: 64),
                    const SizedBox(height: 16),
                    const Text('تم تأكيد البريد', style: AppText.h2,
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 8),
                    Text('يمكنك الآن تسجيل الدخول', style: AppText.body,
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 24),
                    GradientButton(
                        label: 'تسجيل الدخول',
                        onTap: () => context.go('/login')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
