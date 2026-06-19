import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_input.dart';
import '../../../core/widgets/gradient_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _reset() async {
    if (_passCtrl.text.isEmpty) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.resetPassword('', _passCtrl.text.trim());
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      setState(() => _error = 'فشل تغيير كلمة المرور');
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
                child: const Text('إعادة تعيين كلمة المرور',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 24,
                      fontWeight: FontWeight.w800, color: Colors.white,
                    ),
                    textDirection: TextDirection.rtl),
              ),
              const SizedBox(height: 8),
              Text('أدخل كلمة المرور الجديدة', style: AppText.body,
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 40),
              GlassCard(
                child: Column(children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neonRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!,
                          style: AppText.body.copyWith(color: AppColors.neonRed),
                          textDirection: TextDirection.rtl),
                    ),
                    const SizedBox(height: 16),
                  ],
                  GlassInput(
                      hint: 'كلمة المرور الجديدة',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _passCtrl),
                  const SizedBox(height: 12),
                  GlassInput(
                      hint: 'تأكيد كلمة المرور',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _confirmCtrl),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'تغيير كلمة المرور',
                    isLoading: _loading,
                    onTap: _reset,
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
