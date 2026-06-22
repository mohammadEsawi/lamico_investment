import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/animated_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kpi_card.dart';
import '../widgets/admin_nav.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/desktop_sidebar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _overview;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/dashboard/overview');
      setState(() { _overview = res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: Row(children: [
        if (Responsive.isDesktop(context)) const DesktopSidebar(role: 'ADMIN'),
        Expanded(child: AiBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.bgCard,
              elevation: 0,
              toolbarHeight: 64,
              automaticallyImplyLeading: false,
              flexibleSpace: AiAppBar(
                title: 'لوحة التحكم',
                actions: [
                  const NotificationBell(),
                  const CircleAvatar(
                      radius: 16, backgroundColor: AppColors.neonPurple),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnimatedCard(
                    child: GlassCard(
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مرحباً، ${user?.name ?? 'مدير'}',
                                  style: AppText.h2,
                                  textDirection: TextDirection.rtl),
                              const SizedBox(height: 4),
                              Text('إليك ملخص اليوم',
                                  style: AppText.body,
                                  textDirection: TextDirection.rtl),
                            ],
                          )),
                          ShaderMask(
                            shaderCallback: (b) =>
                                AppColors.primaryGrad.createShader(b),
                            child: const Icon(Icons.dashboard_customize,
                                size: 40, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator(
                        color: AppColors.neonPurple))
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        AnimatedCard(delay: 0, child: KpiCard(
                          label: 'إجمالي الموظفين',
                          value: '${_overview?['totalUsers'] ?? '--'}',
                          gradient: AppColors.primaryGrad,
                          icon: Icons.people_outline,
                        )),
                        AnimatedCard(delay: 100, child: KpiCard(
                          label: 'إنتاج اليوم (كرتون)',
                          value: '${_overview?['todayProduction'] ?? '--'}',
                          gradient: AppColors.successGrad,
                          icon: Icons.inventory_2_outlined,
                        )),
                        AnimatedCard(delay: 200, child: KpiCard(
                          label: 'الآلات التشغيلية',
                          value: '${_overview?['operationalMachines'] ?? '--'}',
                          gradient: AppColors.goldGrad,
                          icon: Icons.precision_manufacturing_outlined,
                        )),
                        AnimatedCard(delay: 300, child: KpiCard(
                          label: 'تنبيهات الجودة',
                          value: '${_overview?['qualityAlerts'] ?? '--'}',
                          gradient: AppColors.warningGrad,
                          icon: Icons.warning_amber_outlined,
                        )),
                      ],
                    ),
                  const SizedBox(height: 16),
                  AnimatedCard(
                    delay: 200,
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              ShaderMask(
                                shaderCallback: (b) =>
                                    AppColors.primaryGrad.createShader(b),
                                child: const Icon(Icons.bar_chart,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Text('الإنتاج — آخر 7 أيام', style: AppText.h3),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 120,
                            child: Center(
                              child: Text('تحميل الرسم البياني...',
                                  style: AppText.caption),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedCard(
                    delay: 300,
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              const Icon(Icons.link,
                                  color: AppColors.neonCyan, size: 20),
                              const SizedBox(width: 8),
                              Text('الوصول السريع', style: AppText.h3),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _quickBtn('الحضور', Icons.fingerprint,
                                  AppColors.neonCyan,
                                  () => context.push('/admin/attendance')),
                              _quickBtn('الرواتب', Icons.payments_outlined,
                                  AppColors.neonGreen,
                                  () => context.push('/admin/payroll')),
                              _quickBtn('الطلبات', Icons.how_to_reg_outlined,
                                  AppColors.neonGold,
                                  () => context.push('/admin/requests')),
                              _quickBtn('الإعدادات', Icons.settings_outlined,
                                  AppColors.textSecondary,
                                  () => context.push('/admin/settings')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      )),
    ]),
    );
  }

  Widget _quickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: AppText.caption.copyWith(color: color)),
        ]),
      ),
    );
  }
}
