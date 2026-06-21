import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_input.dart';
import '../../../core/widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  String _selectedRole = 'WORKER';
  bool _loading = false;
  String? _error;
  String? _success;

  static const _roles = [
    ('WORKER', 'عامل'),
    ('ENGINEER', 'مهندس'),
    ('ACCOUNTANT', 'محاسب'),
    ('SALES_REP', 'مندوب مبيعات'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await AuthService.register({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text.trim(),
        'role': _selectedRole,
      });
      setState(() => _success = 'تم إنشاء الحساب، راجع بريدك للتفعيل');
    } catch (e) {
      setState(() => _error = 'فشل إنشاء الحساب، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AiBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
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
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGrad.createShader(b),
                  child: const Text('إنشاء حساب',
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 28,
                        fontWeight: FontWeight.w800, color: Colors.white,
                      ),
                      textDirection: TextDirection.rtl),
                ),
                const SizedBox(height: 8),
                Text('سجّل بياناتك للانضمام', style: AppText.body,
                    textDirection: TextDirection.rtl),
                const SizedBox(height: 32),
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
                    if (_success != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_success!,
                            style: AppText.body.copyWith(color: AppColors.neonGreen),
                            textDirection: TextDirection.rtl),
                      ),
                      const SizedBox(height: 16),
                    ],
                    GlassInput(
                        hint: 'الاسم الكامل',
                        icon: Icons.person_outline,
                        controller: _nameCtrl,
                        validator: (v) => v == null || v.isEmpty ? 'أدخل الاسم' : null),
                    const SizedBox(height: 12),
                    GlassInput(
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل البريد';
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                            return 'البريد الإلكتروني غير صحيح';
                          }
                          return null;
                        }),
                    const SizedBox(height: 12),
                    GlassInput(
                        hint: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passCtrl,
                        validator: (v) {
                          if (v == null || v.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                          if (!RegExp(r'[A-Z]').hasMatch(v)) return 'يجب أن تحتوي على حرف كبير';
                          if (!RegExp(r'[a-z]').hasMatch(v)) return 'يجب أن تحتوي على حرف صغير';
                          if (!RegExp(r'[0-9]').hasMatch(v)) return 'يجب أن تحتوي على رقم';
                          return null;
                        }),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          dropdownColor: AppColors.bgCard,
                          style: AppText.body.copyWith(color: AppColors.textPrimary),
                          items: _roles.map((r) => DropdownMenuItem(
                            value: r.$1,
                            child: Text(r.$2, textDirection: TextDirection.rtl),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedRole = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'إنشاء حساب',
                      isLoading: _loading,
                      onTap: _register,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text('لديك حساب؟ سجّل الدخول',
                          style: AppText.body.copyWith(color: AppColors.neonCyan)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
