import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/animated_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerDashboardScreen extends StatefulWidget {
  const EngineerDashboardScreen({super.key});
  @override
  State<EngineerDashboardScreen> createState() => _EngineerDashboardScreenState();
}

class _EngineerDashboardScreenState extends State<EngineerDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/dashboard/overview');
      setState(() { _data = res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 0),
      body: AiBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.bgCard,
              elevation: 0,
              toolbarHeight: 64,
              automaticallyImplyLeading: false,
              flexibleSpace: AiAppBar(
                title: 'لوحة المهندس',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () => context.push('/notifications'),
                  ),
                  const CircleAvatar(radius: 16, backgroundColor: AppColors.neonCyan),
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
                              Text('مرحباً، ${user?.name ?? 'مهندس'}',
                                  style: AppText.h2, textDirection: TextDirection.rtl),
                              const SizedBox(height: 4),
                              Text('متابعة حالة الآلات والصيانة',
                                  style: AppText.body, textDirection: TextDirection.rtl),
                            ],
                          )),
                          ShaderMask(
                            shaderCallback: (b) => AppColors.successGrad.createShader(b),
                            child: const Icon(Icons.engineering, size: 40, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const LoadingWidget()
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
                          label: 'الآلات التشغيلية',
                          value: '${_data?['operationalMachines'] ?? '--'}',
                          gradient: AppColors.successGrad,
                          icon: Icons.precision_manufacturing_outlined,
                        )),
                        AnimatedCard(delay: 100, child: KpiCard(
                          label: 'طلبات الصيانة',
                          value: '${_data?['openMaintenanceRequests'] ?? '--'}',
                          gradient: AppColors.warningGrad,
                          icon: Icons.build_outlined,
                        )),
                        AnimatedCard(delay: 200, child: KpiCard(
                          label: 'تنبيهات الجودة',
                          value: '${_data?['qualityAlerts'] ?? '--'}',
                          gradient: AppColors.primaryGrad,
                          icon: Icons.warning_amber_outlined,
                        )),
                        AnimatedCard(delay: 300, child: KpiCard(
                          label: 'قطع الغيار',
                          value: '${_data?['spareParts'] ?? '--'}',
                          gradient: AppColors.goldGrad,
                          icon: Icons.settings_outlined,
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
                          Row(textDirection: TextDirection.rtl, children: [
                            const Icon(Icons.link, color: AppColors.neonCyan, size: 20),
                            const SizedBox(width: 8),
                            Text('الوصول السريع', style: AppText.h3),
                          ]),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _quickBtn('صيانة', Icons.build_outlined, AppColors.neonCyan,
                                () => context.push('/engineer/maintenance')),
                            _quickBtn('جودة', Icons.verified_outlined, AppColors.neonGreen,
                                () => context.push('/engineer/quality')),
                            _quickBtn('قطع غيار', Icons.settings_outlined, AppColors.neonGold,
                                () => context.push('/engineer/spare-parts')),
                            _quickBtn('وثائق', Icons.description_outlined, AppColors.neonPurple,
                                () => context.push('/engineer/documents')),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
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
