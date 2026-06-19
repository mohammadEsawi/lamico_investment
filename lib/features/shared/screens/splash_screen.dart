import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = await AuthService.restoreSession();
    if (!mounted) return;
    if (user == null) {
      context.go('/login');
      return;
    }
    switch (user.role) {
      case 'ADMIN':      context.go('/admin'); break;
      case 'ENGINEER':   context.go('/engineer'); break;
      case 'ACCOUNTANT': context.go('/accountant'); break;
      case 'WORKER':     context.go('/worker'); break;
      case 'SALES_REP':  context.go('/sales'); break;
      default:           context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AiBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.neonPurple.withValues(alpha: 0.3),
                    Colors.transparent,
                  ]),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.show_chart,
                      size: 60, color: AppColors.neonPurple),
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (b) => AppColors.primaryGrad.createShader(b),
                child: const Text('لاميكو الاستثمارية', style: AppText.hero,
                    textDirection: TextDirection.rtl),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGrad,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('بيتا',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 12, color: Colors.white,
                      fontWeight: FontWeight.w600, letterSpacing: 2,
                    )),
              ),
              const SizedBox(height: 8),
              Text('نظام إدارة المصنع الذكي',
                  style: AppText.caption,
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: AppColors.neonPurple),
            ],
          ),
        ),
      ),
    );
  }
}
