import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/profile/me');
      setState(() { _profile = res.data; _loading = false; });
    } catch (_) {
      final user = AuthService.currentUser;
      if (user != null) {
        setState(() { _profile = user.toJson(); _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الملف الشخصي'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Avatar section
                      Center(
                        child: Column(children: [
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    AppColors.neonPurple.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ]),
                                ),
                              ),
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
                                child: Text(
                                  (user?.name ?? _profile?['name'] ?? 'U').toString().isNotEmpty
                                      ? (user?.name ?? _profile?['name'] ?? 'U').toString()[0].toUpperCase()
                                      : 'U',
                                  style: AppText.hero.copyWith(color: AppColors.neonPurple),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _profile?['name'] ?? user?.name ?? '--',
                            style: AppText.h2,
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGrad,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user?.roleArabic ?? _profile?['role'] ?? '--',
                              style: const TextStyle(
                                  fontFamily: 'Cairo', fontSize: 12,
                                  color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ]),
                      ),

                      // Info card
                      GlassCard(
                        child: Column(children: [
                          _infoRow(Icons.email_outlined, 'البريد الإلكتروني',
                              _profile?['email'] ?? user?.email ?? '--'),
                          const Divider(color: AppColors.border, height: 24),
                          _infoRow(Icons.badge_outlined, 'الدور الوظيفي',
                              user?.roleArabic ?? _profile?['role'] ?? '--'),
                          const Divider(color: AppColors.border, height: 24),
                          _infoRow(Icons.toggle_on_outlined, 'الحالة',
                              (_profile?['isActive'] ?? user?.isActive ?? true)
                                  ? 'نشط' : 'غير نشط'),
                          if (_profile?['phone'] != null) ...[
                            const Divider(color: AppColors.border, height: 24),
                            _infoRow(Icons.phone_outlined, 'الهاتف',
                                _profile!['phone']),
                          ],
                          if (_profile?['department'] != null) ...[
                            const Divider(color: AppColors.border, height: 24),
                            _infoRow(Icons.business_outlined, 'القسم',
                                _profile!['department']),
                          ],
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // Stats card
                      if (_profile != null) GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(textDirection: TextDirection.rtl, children: [
                              const Icon(Icons.insights, color: AppColors.neonPurple, size: 20),
                              const SizedBox(width: 8),
                              Text('إحصائيات', style: AppText.h3),
                            ]),
                            const SizedBox(height: 12),
                            Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _stat('أيام الحضور', '${_profile?['attendanceDays'] ?? '--'}'),
                                _stat('مهام مكتملة', '${_profile?['completedTasks'] ?? '--'}'),
                                _stat('تقييم الأداء', '${_profile?['performanceScore'] ?? '--'}'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      GradientButton(
                        label: 'تسجيل الخروج',
                        gradient: AppColors.warningGrad,
                        onTap: _logout,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: AppColors.neonPurple, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.label, textDirection: TextDirection.rtl),
              const SizedBox(height: 2),
              Text(value, style: AppText.body.copyWith(color: AppColors.textPrimary),
                  textDirection: TextDirection.rtl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      ShaderMask(
        shaderCallback: (b) => AppColors.primaryGrad.createShader(b),
        child: Text(value, style: AppText.h2.copyWith(color: Colors.white)),
      ),
      Text(label, style: AppText.caption, textDirection: TextDirection.rtl),
    ]);
  }
}
