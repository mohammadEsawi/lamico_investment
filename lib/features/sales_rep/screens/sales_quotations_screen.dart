import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_format.dart';
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
        AppDate.sortDesc(_items);
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

  Widget _field(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.text, int maxLines = 1}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: TextField(
        controller: ctrl, keyboardType: type, textAlign: TextAlign.right, maxLines: maxLines,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
            hintText: hint, hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );

  void _showCreate() {
    final customerCtrl = TextEditingController();
    final totalCtrl    = TextEditingController();
    final notesCtrl    = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('عرض سعر جديد', style: AppText.h3),
            const SizedBox(height: 14),
            _field(customerCtrl, 'اسم العميل *',    AppColors.neonGold),
            const SizedBox(height: 10),
            _field(totalCtrl,    'الإجمالي *',      AppColors.neonGreen, type: TextInputType.number),
            const SizedBox(height: 10),
            _field(notesCtrl,    'ملاحظات',         AppColors.textSecondary, maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  final customer = customerCtrl.text.trim();
                  final total    = double.tryParse(totalCtrl.text);
                  if (customer.isEmpty || total == null) return;
                  Navigator.pop(ctx);
                  try {
                    await ApiService.post('/sales-rep/quotations', data: {
                      'customerName': customer,
                      'total':        total,
                      if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                    });
                    _load();
                  } catch (_) {}
                },
                child: const Text('إنشاء عرض السعر',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showActions(Map<String, dynamic> q) {
    String status = q['status'] ?? 'PENDING';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(q['quotationNumber'] ?? q['number'] ?? 'عرض السعر', style: AppText.h3),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.3))),
                child: DropdownButton<String>(
                  value: status,
                  isExpanded: true,
                  dropdownColor: AppColors.bgCard,
                  underline: const SizedBox(),
                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'PENDING',  child: Text('معلق')),
                    DropdownMenuItem(value: 'ACCEPTED', child: Text('مقبول')),
                    DropdownMenuItem(value: 'REJECTED', child: Text('مرفوض')),
                  ],
                  onChanged: (v) => ss(() => status = v!),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonRed),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            backgroundColor: AppColors.bgCard,
                            title: const Text('حذف عرض السعر'),
                            content: const Text('هل تريد حذف هذا العرض؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                              TextButton(onPressed: () => Navigator.pop(c, true),
                                  child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
                            ],
                          ),
                        ),
                      );
                      if (ok == true) {
                        try { await ApiService.delete('/sales-rep/quotations/${q['id']}'); _load(); } catch (_) {}
                      }
                    },
                    child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.patch('/sales-rep/quotations/${q['id']}/status',
                            data: {'status': status});
                        _load();
                      } catch (_) {}
                    },
                    child: const Text('تحديث الحالة',
                        style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const SalesNav(selectedIndex: 2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGold,
        onPressed: _showCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final q = _items[i] as Map<String, dynamic>;
                            final status = q['status'] as String?;
                            final color = _statusColor(status);
                            return GestureDetector(
                              onLongPress: () => _showActions(q),
                              child: GlassCard(
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
                                          Text(AppDate.format(q['createdAt']),
                                              style: AppText.label, textDirection: TextDirection.rtl),
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
