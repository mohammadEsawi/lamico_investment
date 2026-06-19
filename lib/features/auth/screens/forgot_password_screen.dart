import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_input.dart';
import '../../../core/widgets/gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthService.forgotPassword(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } catch (_) {
      setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AiBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 20),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward,
                      color: AppColors.textSecondary),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (b) => AppColors.primaryGrad.createShader(b),
                child: const Text('نسيت كلمة المرور',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 26,
                      fontWeight: FontWeight.w800, color: Colors.white,
                    ),
                    textDirection: TextDirection.rtl),
              ),
              const SizedBox(height: 8),
              Text('أدخل بريدك وسنرسل رابط الاسترداد', style: AppText.body,
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 40),
              if (_sent)
                GlassCard(
                  child: Column(children: [
                    const Icon(Icons.mark_email_read_outlined,
                        color: AppColors.neonGreen, size: 48),
                    const SizedBox(height: 12),
                    const Text('تم الإرسال!', style: AppText.h2,
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 8),
                    Text('تحقق من بريدك الإلكتروني', style: AppText.body,
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 20),
                    GradientButton(
                        label: 'العودة لتسجيل الدخول',
                        gradient: AppColors.primaryGrad,
                        onTap: () => context.go('/login')),
                  ]),
                )
              else
                GlassCard(
                  child: Column(children: [
                    GlassInput(
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'إرسال رابط الاسترداد',
                      isLoading: _loading,
                      onTap: _send,
                    ),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
