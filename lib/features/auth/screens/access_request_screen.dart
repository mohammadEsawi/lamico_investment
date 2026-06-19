import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_input.dart';
import '../../../core/widgets/gradient_button.dart';

class AccessRequestScreen extends StatefulWidget {
  const AccessRequestScreen({super.key});

  @override
  State<AccessRequestScreen> createState() => _AccessRequestScreenState();
}

class _AccessRequestScreenState extends State<AccessRequestScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _noteCtrl  = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.post('/registration-request/', data: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'notes': _noteCtrl.text.trim(),
      });
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
          child: SingleChildScrollView(
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
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (b) => AppColors.primaryGrad.createShader(b),
                child: const Text('طلب الوصول',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 26,
                      fontWeight: FontWeight.w800, color: Colors.white,
                    ),
                    textDirection: TextDirection.rtl),
              ),
              const SizedBox(height: 8),
              Text('أرسل طلبك وسيتم مراجعته من قِبل المدير',
                  style: AppText.body, textDirection: TextDirection.rtl),
              const SizedBox(height: 32),
              _sent
                  ? GlassCard(
                      child: Column(children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.neonGreen, size: 56),
                        const SizedBox(height: 12),
                        const Text('تم إرسال طلبك', style: AppText.h2,
                            textDirection: TextDirection.rtl),
                        const SizedBox(height: 8),
                        Text('سيراجع المدير طلبك قريباً',
                            style: AppText.body,
                            textDirection: TextDirection.rtl),
                        const SizedBox(height: 20),
                        GradientButton(
                            label: 'العودة',
                            onTap: () => context.go('/login')),
                      ]),
                    )
                  : GlassCard(
                      child: Column(children: [
                        GlassInput(hint: 'الاسم الكامل',
                            icon: Icons.person_outline,
                            controller: _nameCtrl),
                        const SizedBox(height: 12),
                        GlassInput(hint: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        GlassInput(hint: 'ملاحظات (اختياري)',
                            icon: Icons.note_outlined,
                            controller: _noteCtrl),
                        const SizedBox(height: 20),
                        GradientButton(
                          label: 'إرسال الطلب',
                          isLoading: _loading,
                          onTap: _submit,
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
