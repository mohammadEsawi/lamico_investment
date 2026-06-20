import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/accountant_nav.dart';

class AccountantBudgetScreen extends StatefulWidget {
  const AccountantBudgetScreen({super.key});
  @override
  State<AccountantBudgetScreen> createState() => _AccountantBudgetScreenState();
}

class _AccountantBudgetScreenState extends State<AccountantBudgetScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/budgets');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['plans'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AccountantNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'خطة الميزانية'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد خطط ميزانية', icon: Icons.account_balance_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final b = _items[i];
                            final allocated = b['allocatedAmount'] ?? b['budget'] ?? 0;
                            final spent = b['spentAmount'] ?? b['spent'] ?? 0;
                            final pct = allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0;
                            return GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(b['category'] ?? b['name'] ?? '--',
                                          style: AppText.h3, textDirection: TextDirection.rtl),
                                      Text('${(pct * 100).toStringAsFixed(0)}%',
                                          style: AppText.h3.copyWith(color: AppColors.neonPurple)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct.toDouble(),
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        pct > 0.9 ? AppColors.neonRed : AppColors.neonPurple,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('المخصص: $allocated ج.م', style: AppText.caption),
                                      Text('المنفق: $spent ج.م', style: AppText.caption),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}
