import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/accountant_nav.dart';

class AccountantPayablesScreen extends StatefulWidget {
  const AccountantPayablesScreen({super.key});
  @override
  State<AccountantPayablesScreen> createState() => _AccountantPayablesScreenState();
}

class _AccountantPayablesScreenState extends State<AccountantPayablesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/supplier-payables');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['payables'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Widget _field(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.text}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: TextField(
        controller: ctrl, keyboardType: type, textAlign: TextAlign.right,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
            hintText: hint, hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );

  void _showForm([Map<String, dynamic>? payable]) {
    final isEdit        = payable != null;
    final supplierCtrl  = TextEditingController(
        text: payable?['supplier']?['name'] ?? payable?['supplierName'] ?? '');
    final amountCtrl    = TextEditingController(text: '${payable?['amount'] ?? ''}');
    final dueDateCtrl   = TextEditingController(
        text: payable?['dueDate']?.toString().substring(0, 10) ?? '');
    final notesCtrl     = TextEditingController(text: payable?['notes'] ?? '');

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
            Text(isEdit ? 'تعديل المستحق' : 'مستحق مورد جديد', style: AppText.h3),
            const SizedBox(height: 14),
            _field(supplierCtrl, 'اسم المورد *',      AppColors.neonOrange),
            const SizedBox(height: 10),
            _field(amountCtrl,   'المبلغ *',           AppColors.neonRed, type: TextInputType.number),
            const SizedBox(height: 10),
            _field(dueDateCtrl,  'تاريخ الاستحقاق',   AppColors.neonGold, type: TextInputType.datetime),
            const SizedBox(height: 10),
            _field(notesCtrl,    'ملاحظات',            AppColors.textSecondary),
            const SizedBox(height: 16),
            if (isEdit) Row(children: [
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
                          title: const Text('حذف المستحق'),
                          content: const Text('هل تريد حذف هذا المستحق؟'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                            TextButton(onPressed: () => Navigator.pop(c, true),
                                child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
                          ],
                        ),
                      ),
                    );
                    if (ok == true) {
                      try { await ApiService.delete('/supplier-payables/${payable['id']}'); _load(); } catch (_) {}
                    }
                  },
                  child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _saveBtn(ctx, isEdit, payable, supplierCtrl, amountCtrl, dueDateCtrl, notesCtrl)),
            ]) else SizedBox(
              width: double.infinity,
              child: _saveBtn(ctx, isEdit, payable, supplierCtrl, amountCtrl, dueDateCtrl, notesCtrl),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _saveBtn(BuildContext ctx, bool isEdit, Map<String, dynamic>? payable,
      TextEditingController supplierCtrl, TextEditingController amountCtrl,
      TextEditingController dueDateCtrl,  TextEditingController notesCtrl) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () async {
        final supplier = supplierCtrl.text.trim();
        final amount   = double.tryParse(amountCtrl.text);
        if (supplier.isEmpty || amount == null) return;
        Navigator.pop(ctx);
        try {
          final body = {
            'supplierName': supplier,
            'amount':       amount,
            if (dueDateCtrl.text.isNotEmpty) 'dueDate': dueDateCtrl.text.trim(),
            if (notesCtrl.text.isNotEmpty)   'notes':   notesCtrl.text.trim(),
          };
          if (isEdit) {
            await ApiService.patch('/supplier-payables/${payable!['id']}', data: body);
          } else {
            await ApiService.post('/supplier-payables', data: body);
          }
          _load();
        } catch (_) {}
      },
      child: Text(isEdit ? 'حفظ' : 'إضافة',
          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AccountantNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonOrange,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'مستحقات الموردين'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد مستحقات موردين', icon: Icons.business_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final p = _items[i] as Map<String, dynamic>;
                            return GestureDetector(
                              onLongPress: () => _showForm(p),
                              child: GlassCard(
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonOrange.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.business_outlined, color: AppColors.neonOrange),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['supplier']?['name'] ?? p['supplierName'] ?? '--',
                                              style: AppText.h3, textDirection: TextDirection.rtl),
                                          Text('تاريخ الاستحقاق: ${p['dueDate']?.toString().substring(0, 10) ?? '--'}',
                                              style: AppText.caption, textDirection: TextDirection.rtl),
                                        ],
                                      ),
                                    ),
                                    Text('${p['amount'] ?? '--'} ج.م',
                                        style: AppText.h3.copyWith(color: AppColors.neonOrange)),
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
