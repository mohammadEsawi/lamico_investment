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
import '../widgets/sales_nav.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});
  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/sales-rep/dashboard');
      setState(() { _data = res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const SalesNav(selectedIndex: 0),
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
                title: 'لوحة المبيعات',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                    onPressed: () => context.push('/notifications'),
                  ),
                  const SalesMoreMenu(),
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
                              Text('مرحباً، ${user?.name ?? 'مندوب'}',
                                  style: AppText.h2, textDirection: TextDirection.rtl),
                              const SizedBox(height: 4),
                              Text('ملخص أداء المبيعات', style: AppText.body,
                                  textDirection: TextDirection.rtl),
                            ],
                          )),
                          ShaderMask(
                            shaderCallback: (b) => AppColors.goldGrad.createShader(b),
                            child: const Icon(Icons.trending_up, size: 40, color: Colors.white),
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
                          label: 'إجمالي المبيعات',
                          value: '${_data?['totalSales'] ?? '--'}',
                          gradient: AppColors.goldGrad,
                          icon: Icons.attach_money,
                        )),
                        AnimatedCard(delay: 100, child: KpiCard(
                          label: 'العملاء النشطون',
                          value: '${_data?['activeCustomers'] ?? '--'}',
                          gradient: AppColors.successGrad,
                          icon: Icons.people_outline,
                        )),
                        AnimatedCard(delay: 200, child: KpiCard(
                          label: 'عروض الأسعار',
                          value: '${_data?['pendingQuotations'] ?? '--'}',
                          gradient: AppColors.primaryGrad,
                          icon: Icons.request_quote_outlined,
                        )),
                        AnimatedCard(delay: 300, child: KpiCard(
                          label: 'نسبة إنجاز الهدف',
                          value: '${_data?['targetAchievement'] ?? '--'}%',
                          gradient: AppColors.warningGrad,
                          icon: Icons.flag_outlined,
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
                            const Icon(Icons.link, color: AppColors.neonGold, size: 20),
                            const SizedBox(width: 8),
                            Text('الوصول السريع', style: AppText.h3),
                          ]),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _quickBtn('عملاء', Icons.people_outline, AppColors.neonGold,
                                () => context.push('/sales/customers')),
                            _quickBtn('عروض', Icons.request_quote_outlined, AppColors.neonCyan,
                                () => context.push('/sales/quotations')),
                            _quickBtn('زيارات', Icons.directions_car_outlined, AppColors.neonGreen,
                                () => context.push('/sales/visits')),
                            _quickBtn('أهداف', Icons.flag_outlined, AppColors.neonPurple,
                                () => context.push('/sales/targets')),
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
