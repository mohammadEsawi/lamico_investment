import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/accountant_nav.dart';

class AccountantReceivablesScreen extends StatefulWidget {
  const AccountantReceivablesScreen({super.key});
  @override
  State<AccountantReceivablesScreen> createState() => _AccountantReceivablesScreenState();
}

class _AccountantReceivablesScreenState extends State<AccountantReceivablesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/customer-receivables');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['receivables'] ?? data['data'] ?? []);
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
          AiAppBar(title: 'مستحقات العملاء'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد مستحقات عملاء', icon: Icons.people_outline)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _items[i];
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonCyan.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.person_outline, color: AppColors.neonCyan),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r['customer']?['name'] ?? r['customerName'] ?? '--',
                                            style: AppText.h3, textDirection: TextDirection.rtl),
                                        Text('تاريخ الاستحقاق: ${r['dueDate']?.toString().substring(0, 10) ?? '--'}',
                                            style: AppText.caption, textDirection: TextDirection.rtl),
                                      ],
                                    ),
                                  ),
                                  Text('${r['amount'] ?? '--'} ج.م',
                                      style: AppText.h3.copyWith(color: AppColors.neonCyan)),
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
