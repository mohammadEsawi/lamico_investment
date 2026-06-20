import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/sales_nav.dart';

class SalesQuotationsScreen extends StatefulWidget {
  const SalesQuotationsScreen({super.key});
  @override
  State<SalesQuotationsScreen> createState() => _SalesQuotationsScreenState();
}

class _SalesQuotationsScreenState extends State<SalesQuotationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/sales-rep/quotations');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['quotations'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'ACCEPTED': return AppColors.neonGreen;
      case 'PENDING':  return AppColors.neonGold;
      case 'REJECTED': return AppColors.neonRed;
      default:         return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'ACCEPTED': return 'مقبول';
      case 'PENDING':  return 'معلق';
      case 'REJECTED': return 'مرفوض';
      default:         return s ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const SalesNav(selectedIndex: 2),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'عروض الأسعار'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد عروض أسعار', icon: Icons.request_quote_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final q = _items[i];
                            final status = q['status'] as String?;
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
                                    child: const Icon(Icons.request_quote, color: AppColors.neonGold),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(q['quotationNumber'] ?? q['number'] ?? '--',
                                            style: AppText.h3, textDirection: TextDirection.rtl),
                                        Text(q['customer']?['name'] ?? q['customerName'] ?? '--',
                                            style: AppText.caption, textDirection: TextDirection.rtl),
                                        Text(q['createdAt']?.toString().substring(0, 10) ?? '--',
                                            style: AppText.label),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${q['total'] ?? '--'} ج.م',
                                          style: AppText.h3.copyWith(color: AppColors.neonGold)),
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
