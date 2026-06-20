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
import '../widgets/accountant_nav.dart';

class AccountantDashboardScreen extends StatefulWidget {
  const AccountantDashboardScreen({super.key});
  @override
  State<AccountantDashboardScreen> createState() => _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState extends State<AccountantDashboardScreen> {
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
      bottomNavigationBar: const AccountantNav(selectedIndex: 0),
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
                title: 'لوحة المالية',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                    onPressed: () => context.push('/notifications'),
                  ),
                  const CircleAvatar(radius: 16, backgroundColor: AppColors.neonGreen),
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
                              Text('مرحباً، ${user?.name ?? 'محاسب'}',
                                  style: AppText.h2, textDirection: TextDirection.rtl),
                              const SizedBox(height: 4),
                              Text('ملخص الوضع المالي', style: AppText.body,
                                  textDirection: TextDirection.rtl),
                            ],
                          )),
                          ShaderMask(
                            shaderCallback: (b) => AppColors.successGrad.createShader(b),
                            child: const Icon(Icons.account_balance, size: 40, color: Colors.white),
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
                          label: 'الإيرادات هذا الشهر',
                          value: '${_data?['monthlyRevenue'] ?? '--'}',
                          gradient: AppColors.successGrad,
                          icon: Icons.trending_up,
                        )),
                        AnimatedCard(delay: 100, child: KpiCard(
                          label: 'المصروفات هذا الشهر',
                          value: '${_data?['monthlyExpenses'] ?? '--'}',
                          gradient: AppColors.warningGrad,
                          icon: Icons.trending_down,
                        )),
                        AnimatedCard(delay: 200, child: KpiCard(
                          label: 'الفواتير المعلقة',
                          value: '${_data?['pendingInvoices'] ?? '--'}',
                          gradient: AppColors.goldGrad,
                          icon: Icons.receipt_long_outlined,
                        )),
                        AnimatedCard(delay: 300, child: KpiCard(
                          label: 'صافي الربح',
                          value: '${_data?['netProfit'] ?? '--'}',
                          gradient: AppColors.primaryGrad,
                          icon: Icons.account_balance_wallet_outlined,
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
                            const Icon(Icons.link, color: AppColors.neonGreen, size: 20),
                            const SizedBox(width: 8),
                            Text('الوصول السريع', style: AppText.h3),
                          ]),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            _quickBtn('فواتير', Icons.receipt_long_outlined, AppColors.neonGreen,
                                () => context.push('/accountant/invoices')),
                            _quickBtn('موردون', Icons.store_outlined, AppColors.neonGold,
                                () => context.push('/accountant/suppliers')),
                            _quickBtn('مصروفات', Icons.money_off_outlined, AppColors.neonRed,
                                () => context.push('/accountant/expenses')),
                            _quickBtn('تقارير', Icons.bar_chart_outlined, AppColors.neonPurple,
                                () => context.push('/accountant/reports')),
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
