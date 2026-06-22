import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_format.dart';
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
        AppDate.sortDesc(_items);
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

  Widget _field(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.text, int maxLines = 1}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: TextField(
        controller: ctrl, keyboardType: type,
        textAlign: TextAlign.right, maxLines: maxLines,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
            hintText: hint, hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );

  void _showCreate() {
    final numCtrl    = TextEditingController();
    final clientCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dueDateCtrl = TextEditingController();
    String status = 'PENDING';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('فاتورة جديدة', style: AppText.h3),
                const SizedBox(height: 14),
                _field(numCtrl,    'رقم الفاتورة *',  AppColors.neonGreen),
                const SizedBox(height: 10),
                _field(clientCtrl, 'اسم العميل *',    AppColors.neonCyan),
                const SizedBox(height: 10),
                _field(amountCtrl, 'المبلغ *',        AppColors.neonPurple, type: TextInputType.number),
                const SizedBox(height: 10),
                _field(dueDateCtrl,'تاريخ الاستحقاق', AppColors.neonGold, type: TextInputType.datetime),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3))),
                  child: DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    dropdownColor: AppColors.bgCard,
                    underline: const SizedBox(),
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'PENDING', child: Text('معلقة')),
                      DropdownMenuItem(value: 'PAID',    child: Text('مدفوعة')),
                      DropdownMenuItem(value: 'OVERDUE', child: Text('متأخرة')),
                    ],
                    onChanged: (v) => ss(() => status = v!),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      final num   = numCtrl.text.trim();
                      final client = clientCtrl.text.trim();
                      final amount = double.tryParse(amountCtrl.text);
                      if (num.isEmpty || client.isEmpty || amount == null) return;
                      Navigator.pop(ctx);
                      try {
                        await ApiService.post('/invoices', data: {
                          'invoiceNumber': num,
                          'clientName':    client,
                          'total':         amount,
                          'status':        status,
                          if (dueDateCtrl.text.isNotEmpty) 'dueDate': dueDateCtrl.text.trim(),
                        });
                        _load();
                      } catch (_) {}
                    },
                    child: const Text('إنشاء الفاتورة',
                        style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showEdit(Map<String, dynamic> inv) {
    final numCtrl    = TextEditingController(text: inv['invoiceNumber'] ?? inv['number'] ?? '');
    final clientCtrl = TextEditingController(text: inv['clientName'] ?? '');
    final amountCtrl = TextEditingController(text: '${inv['total'] ?? inv['amount'] ?? ''}');
    String status    = inv['status'] ?? 'PENDING';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('تعديل الفاتورة', style: AppText.h3),
              const SizedBox(height: 14),
              _field(numCtrl,    'رقم الفاتورة', AppColors.neonGreen),
              const SizedBox(height: 10),
              _field(clientCtrl, 'اسم العميل',   AppColors.neonCyan),
              const SizedBox(height: 10),
              _field(amountCtrl, 'المبلغ',       AppColors.neonPurple, type: TextInputType.number),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3))),
                child: DropdownButton<String>(
                  value: status,
                  isExpanded: true,
                  dropdownColor: AppColors.bgCard,
                  underline: const SizedBox(),
                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'PENDING', child: Text('معلقة')),
                    DropdownMenuItem(value: 'PAID',    child: Text('مدفوعة')),
                    DropdownMenuItem(value: 'OVERDUE', child: Text('متأخرة')),
                  ],
                  onChanged: (v) => ss(() => status = v!),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonGreen),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('دفع', style: TextStyle(fontFamily: 'Cairo')),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.patch('/invoices/${inv['id']}/payment',
                            data: {'paymentDate': DateTime.now().toIso8601String()});
                        _load();
                      } catch (_) {}
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo')),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.patch('/invoices/${inv['id']}/confirm', data: {});
                        _load();
                      } catch (_) {}
                    },
                  ),
                ),
              ]),
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
                            title: const Text('حذف الفاتورة'),
                            content: const Text('هل تريد حذف هذه الفاتورة؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                              TextButton(onPressed: () => Navigator.pop(c, true),
                                  child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
                            ],
                          ),
                        ),
                      );
                      if (ok == true) {
                        try { await ApiService.delete('/invoices/${inv['id']}'); _load(); } catch (_) {}
                      }
                    },
                    child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.patch('/invoices/${inv['id']}', data: {
                          'invoiceNumber': numCtrl.text.trim(),
                          'clientName':    clientCtrl.text.trim(),
                          if (amountCtrl.text.isNotEmpty)
                            'total': double.tryParse(amountCtrl.text) ?? 0,
                          'status': status,
                        });
                        _load();
                      } catch (_) {}
                    },
                    child: const Text('حفظ',
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
      bottomNavigationBar: const AccountantNav(selectedIndex: 1),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGreen,
        onPressed: _showCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final inv = _items[i] as Map<String, dynamic>;
                            final status = inv['status'] as String?;
                            final color = _statusColor(status);
                            return GestureDetector(
                              onLongPress: () => _showEdit(inv),
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
                                          Text('استحقاق: ${AppDate.format(inv['dueDate'])}',
                                              style: AppText.label, textDirection: TextDirection.rtl),
                                          Text(AppDate.format(inv['createdAt']),
                                              style: AppText.label.copyWith(color: AppColors.textSecondary),
                                              textDirection: TextDirection.rtl),
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
