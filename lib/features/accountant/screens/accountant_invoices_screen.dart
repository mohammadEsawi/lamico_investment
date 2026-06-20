import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/accountant_nav.dart';

class AccountantInvoicesScreen extends StatefulWidget {
  const AccountantInvoicesScreen({super.key});
  @override
  State<AccountantInvoicesScreen> createState() => _AccountantInvoicesScreenState();
}

class _AccountantInvoicesScreenState extends State<AccountantInvoicesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/invoices');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['invoices'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'PAID':    return AppColors.neonGreen;
      case 'PENDING': return AppColors.neonGold;
      case 'OVERDUE': return AppColors.neonRed;
      default:        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'PAID':    return 'مدفوعة';
      case 'PENDING': return 'معلقة';
      case 'OVERDUE': return 'متأخرة';
      default:        return s ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AccountantNav(selectedIndex: 1),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الفواتير'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد فواتير', icon: Icons.receipt_long_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final inv = _items[i];
                            final status = inv['status'] as String?;
                            final color = _statusColor(status);
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.receipt_long, color: AppColors.neonGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(inv['invoiceNumber'] ?? inv['number'] ?? '--',
                                            style: AppText.h3, textDirection: TextDirection.rtl),
                                        Text(inv['customer']?['name'] ?? inv['clientName'] ?? '--',
                                            style: AppText.caption, textDirection: TextDirection.rtl),
                                        Text(inv['dueDate']?.toString().substring(0, 10) ?? '--',
                                            style: AppText.label),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${inv['total'] ?? inv['amount'] ?? '--'} ج.م',
                                          style: AppText.h3.copyWith(color: AppColors.neonGreen)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(_statusLabel(status),
                                            style: AppText.label.copyWith(color: color)),
                                      ),
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
