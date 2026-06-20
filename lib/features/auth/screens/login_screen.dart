import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_input.dart';
import '../../../core/widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.login(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      switch (user.role) {
        case 'ADMIN':      context.go('/admin'); break;
        case 'ENGINEER':   context.go('/engineer'); break;
        case 'ACCOUNTANT': context.go('/accountant'); break;
        case 'WORKER':     context.go('/worker'); break;
        case 'SALES_REP':  context.go('/sales'); break;
        default:           setState(() => _error = 'دور غير معروف');
      }
    } catch (e) {
      setState(() => _error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Column(children: [
                    Stack(alignment: Alignment.center, children: [
                      Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            AppColors.neonPurple.withValues(alpha: 0.3),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                      Image.asset(
                        'assets/images/lamicoLogo.png',
                        width: 100, height: 100,
                        fit: BoxFit.contain,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.primaryGrad.createShader(b),
                      child: const Text('لاميكو الاستثمارية',
                          style: TextStyle(
                            fontFamily: 'Cairo', fontSize: 26,
                            fontWeight: FontWeight.w800, color: Colors.white,
                          ),
                          textDirection: TextDirection.rtl),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGrad,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('بيتا',
                          style: TextStyle(
                            fontFamily: 'Cairo', fontSize: 11,
                            color: Colors.white, fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          )),
                    ),
                    const SizedBox(height: 6),
                    Text('نظام إدارة المصنع الذكي', style: AppText.caption,
                        textDirection: TextDirection.rtl),
                  ]),
                  const SizedBox(height: 48),
                  GlassCard(
                    child: Column(children: [
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مرحباً بك',
                                style: AppText.h2,
                                textDirection: TextDirection.rtl),
                            SizedBox(height: 4),
                            Text('سجّل دخولك للمتابعة',
                                style: AppText.body,
                                textDirection: TextDirection.rtl),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.neonRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.neonRed.withValues(alpha: 0.3)),
                          ),
                          child: Text(_error!,
                              style: AppText.body.copyWith(
                                  color: AppColors.neonRed),
                              textDirection: TextDirection.rtl),
                        ),
                        const SizedBox(height: 16),
                      ],
                      GlassInput(
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'أدخل البريد الإلكتروني' : null,
                      ),
                      const SizedBox(height: 14),
                      GlassInput(
                        hint: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passCtrl,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'أدخل كلمة المرور' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: Text('نسيت كلمة المرور؟',
                              style: AppText.caption.copyWith(
                                  color: AppColors.neonPurple)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GradientButton(
                        label: 'تسجيل الدخول',
                        gradient: AppColors.primaryGrad,
                        isLoading: _loading,
                        onTap: _login,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => context.push('/access-request'),
                            child: Text('طلب الوصول',
                                style: AppText.body.copyWith(
                                    color: AppColors.neonCyan)),
                          ),
                          Text('·', style: AppText.body),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text('إنشاء حساب',
                                style: AppText.body.copyWith(
                                    color: AppColors.neonCyan)),
                          ),
                        ],
                      ),
                    ]),
                  ),
                  const SizedBox(height: 40),
                  Row(children: [
                    Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.08))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.neonPurple, size: 14),
                        const SizedBox(width: 4),
                        Text('مدعوم بالذكاء الاصطناعي',
                            style: AppText.label.copyWith(
                                color: AppColors.neonPurple)),
                      ]),
                    ),
                    Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.08))),
                  ]),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
