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
import '../widgets/worker_nav.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});
  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
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
      bottomNavigationBar: const WorkerNav(selectedIndex: 0),
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
                title: 'لوحة العامل',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                    onPressed: () => context.push('/notifications'),
                  ),
                  const WorkerMoreMenu(),
                  const SizedBox(width: 4),
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
                              Text('مرحباً، ${user?.name ?? 'عامل'}',
                                  style: AppText.h2, textDirection: TextDirection.rtl),
                              const SizedBox(height: 4),
                              Text('سجّل إنتاجك وحضورك اليوم',
                                  style: AppText.body, textDirection: TextDirection.rtl),
                            ],
                          )),
                          ShaderMask(
                            shaderCallback: (b) => AppColors.warningGrad.createShader(b),
                            child: const Icon(Icons.construction, size: 40, color: Colors.white),
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
                          label: 'إنتاج اليوم (كرتون)',
                          value: '${_data?['todayProduction'] ?? '0'}',
                          gradient: AppColors.successGrad,
                          icon: Icons.inventory_2_outlined,
                        )),
                        AnimatedCard(delay: 100, child: KpiCard(
                          label: 'الهدف اليومي',
                          value: '${_data?['dailyTarget'] ?? '--'}',
                          gradient: AppColors.primaryGrad,
                          icon: Icons.flag_outlined,
                        )),
                        AnimatedCard(delay: 200, child: KpiCard(
                          label: 'أيام الحضور',
                          value: '${_data?['attendanceDays'] ?? '--'}',
                          gradient: AppColors.goldGrad,
                          icon: Icons.fingerprint,
                        )),
                        AnimatedCard(delay: 300, child: KpiCard(
                          label: 'الراتب المتوقع',
                          value: '${_data?['expectedSalary'] ?? '--'}',
                          gradient: AppColors.warningGrad,
                          icon: Icons.payments_outlined,
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
                            const Icon(Icons.today, color: AppColors.neonOrange, size: 20),
                            const SizedBox(width: 8),
                            Text('الحضور اليوم', style: AppText.h3),
                          ]),
                          const SizedBox(height: 12),
                          Row(textDirection: TextDirection.rtl, children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.neonGreen,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => context.push('/worker/attendance'),
                                icon: const Icon(Icons.login, size: 18),
                                label: const Text('تسجيل دخول',
                                    style: TextStyle(fontFamily: 'Cairo')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.neonRed,
                                  side: const BorderSide(color: AppColors.neonRed),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => context.push('/worker/attendance'),
                                icon: const Icon(Icons.logout, size: 18),
                                label: const Text('تسجيل خروج',
                                    style: TextStyle(fontFamily: 'Cairo')),
                              ),
                            ),
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
}
