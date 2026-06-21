import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminTaxFilingsScreen extends StatefulWidget {
  const AdminTaxFilingsScreen({super.key});
  @override
  State<AdminTaxFilingsScreen> createState() => _AdminTaxFilingsScreenState();
}

class _AdminTaxFilingsScreenState extends State<AdminTaxFilingsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/tax-filings');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['filings'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
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

  void _showForm([Map<String, dynamic>? filing]) {
    final isEdit      = filing != null;
    final typeCtrl    = TextEditingController(text: filing?['taxType'] ?? filing?['type'] ?? '');
    final periodCtrl  = TextEditingController(text: filing?['period'] ?? '');
    final amountCtrl  = TextEditingController(text: '${filing?['amount'] ?? ''}');
    final dueDateCtrl = TextEditingController(text: filing?['dueDate']?.toString().substring(0, 10) ?? '');
    final notesCtrl   = TextEditingController(text: filing?['notes'] ?? '');
    String status     = filing?['status'] ?? 'PENDING';

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
                Text(isEdit ? 'تعديل الإقرار' : 'إقرار ضريبي جديد', style: AppText.h3),
                const SizedBox(height: 14),
                _field(typeCtrl,    'نوع الضريبة *',        AppColors.neonRed),
                const SizedBox(height: 10),
                _field(periodCtrl,  'الفترة (2025-Q1)',      AppColors.neonGold),
                const SizedBox(height: 10),
                _field(amountCtrl,  'المبلغ *',              AppColors.neonOrange, type: TextInputType.number),
                const SizedBox(height: 10),
                _field(dueDateCtrl, 'تاريخ الاستحقاق',      AppColors.neonCyan,   type: TextInputType.datetime),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3))),
                  child: DropdownButton<String>(
                    value: status, isExpanded: true, dropdownColor: AppColors.bgCard,
                    underline: const SizedBox(),
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'PENDING',  child: Text('معلق')),
                      DropdownMenuItem(value: 'FILED',    child: Text('مُقدَّم')),
                      DropdownMenuItem(value: 'PAID',     child: Text('مدفوع')),
                      DropdownMenuItem(value: 'OVERDUE',  child: Text('متأخر')),
                    ],
                    onChanged: (v) => ss(() => status = v!),
                  ),
                ),
                const SizedBox(height: 10),
                _field(notesCtrl,   'ملاحظات',              AppColors.textSecondary, maxLines: 2),
                const SizedBox(height: 16),
                if (isEdit) Row(children: [
                  Expanded(child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonRed),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await _confirm('حذف الإقرار');
                      if (ok) { try { await ApiService.delete('/tax-filings/${filing['id']}'); _load(); } catch (_) {} }
                    },
                    child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _saveBtn(ctx, isEdit, filing, typeCtrl, periodCtrl, amountCtrl, dueDateCtrl, notesCtrl, status)),
                ]) else SizedBox(width: double.infinity,
                    child: _saveBtn(ctx, isEdit, filing, typeCtrl, periodCtrl, amountCtrl, dueDateCtrl, notesCtrl, status)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveBtn(BuildContext ctx, bool isEdit, Map<String, dynamic>? filing,
      TextEditingController typeCtrl,   TextEditingController periodCtrl,
      TextEditingController amountCtrl, TextEditingController dueDateCtrl,
      TextEditingController notesCtrl,  String status) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () async {
        final type   = typeCtrl.text.trim();
        final amount = double.tryParse(amountCtrl.text);
        if (type.isEmpty || amount == null) return;
        Navigator.pop(ctx);
        try {
          final body = {
            'taxType': type, 'amount': amount, 'status': status,
            if (periodCtrl.text.isNotEmpty)  'period':  periodCtrl.text.trim(),
            if (dueDateCtrl.text.isNotEmpty) 'dueDate': dueDateCtrl.text.trim(),
            if (notesCtrl.text.isNotEmpty)   'notes':   notesCtrl.text.trim(),
          };
          if (isEdit) {
            await ApiService.patch('/tax-filings/${filing!['id']}', data: body);
          } else {
            await ApiService.post('/tax-filings', data: body);
          }
          _load();
        } catch (_) {}
      },
      child: Text(isEdit ? 'حفظ' : 'إضافة',
          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
    );

  Future<bool> _confirm(String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard, title: Text(title),
          content: const Text('هل أنت متأكد؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(c, true),
                child: const Text('تأكيد', style: TextStyle(color: AppColors.neonRed))),
          ],
        ),
      ),
    );
    return ok ?? false;
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'PAID':    return AppColors.neonGreen;
      case 'FILED':   return AppColors.neonCyan;
      case 'PENDING': return AppColors.neonGold;
      case 'OVERDUE': return AppColors.neonRed;
      default:        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'PAID':    return 'مدفوع';
      case 'FILED':   return 'مُقدَّم';
      case 'PENDING': return 'معلق';
      case 'OVERDUE': return 'متأخر';
      default:        return s ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonRed,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الإقرارات الضريبية'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد إقرارات ضريبية', icon: Icons.receipt_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final f = _items[i] as Map<String, dynamic>;
                            final status = f['status'] as String?;
                            final color  = _statusColor(status);
                            return GestureDetector(
                              onLongPress: () => _showForm(f),
                              child: GlassCard(
                                child: Row(textDirection: TextDirection.rtl, children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppColors.neonRed.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.receipt, color: AppColors.neonRed),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f['taxType'] ?? f['type'] ?? '--',
                                          style: AppText.h3, textDirection: TextDirection.rtl),
                                      Text(f['period'] ?? '--', style: AppText.caption,
                                          textDirection: TextDirection.rtl),
                                      Text(f['dueDate']?.toString().substring(0, 10) ?? '--',
                                          style: AppText.label),
                                    ],
                                  )),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('${f['amount'] ?? '--'} ج.م',
                                        style: AppText.h3.copyWith(color: AppColors.neonRed)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Text(_statusLabel(status),
                                          style: AppText.label.copyWith(color: color)),
                                    ),
                                  ]),
                                ]),
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
