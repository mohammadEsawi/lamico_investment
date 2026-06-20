import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/accountant_nav.dart';

class AccountantExpensesScreen extends StatefulWidget {
  const AccountantExpensesScreen({super.key});
  @override
  State<AccountantExpensesScreen> createState() => _AccountantExpensesScreenState();
}

class _AccountantExpensesScreenState extends State<AccountantExpensesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/expenses');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['expenses'] ?? data['data'] ?? []);
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
          AiAppBar(title: 'المصروفات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد مصروفات', icon: Icons.money_off_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final e = _items[i];
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonRed.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.money_off, color: AppColors.neonRed),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e['title'] ?? e['description'] ?? '--',
                                            style: AppText.h3, textDirection: TextDirection.rtl),
                                        Text(e['category'] ?? e['type'] ?? '--',
                                            style: AppText.caption, textDirection: TextDirection.rtl),
                                        Text(e['date']?.toString().substring(0, 10) ?? '--',
                                            style: AppText.label),
                                      ],
                                    ),
                                  ),
                                  Text('${e['amount'] ?? '--'} ج.م',
                                      style: AppText.h3.copyWith(color: AppColors.neonRed)),
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
