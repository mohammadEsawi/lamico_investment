import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminBankReconciliationScreen extends StatefulWidget {
  const AdminBankReconciliationScreen({super.key});
  @override
  State<AdminBankReconciliationScreen> createState() => _AdminBankReconciliationScreenState();
}

class _AdminBankReconciliationScreenState extends State<AdminBankReconciliationScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/bank-reconciliations');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['reconciliations'] ?? data['data'] ?? []);
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

  void _showForm([Map<String, dynamic>? rec]) {
    final isEdit      = rec != null;
    final bankCtrl    = TextEditingController(text: rec?['bankName'] ?? '');
    final balanceCtrl = TextEditingController(text: '${rec?['bankBalance'] ?? ''}');
    final bookCtrl    = TextEditingController(text: '${rec?['bookBalance'] ?? ''}');
    final dateCtrl    = TextEditingController(text: rec?['date']?.toString().substring(0, 10) ?? '');
    final notesCtrl   = TextEditingController(text: rec?['notes'] ?? '');

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
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(isEdit ? 'تعديل المطابقة' : 'مطابقة بنكية جديدة', style: AppText.h3),
              const SizedBox(height: 14),
              _field(bankCtrl,    'اسم البنك *',          AppColors.neonCyan),
              const SizedBox(height: 10),
              _field(balanceCtrl, 'رصيد البنك *',         AppColors.neonGreen,  type: TextInputType.number),
              const SizedBox(height: 10),
              _field(bookCtrl,    'رصيد الدفاتر *',       AppColors.neonPurple, type: TextInputType.number),
              const SizedBox(height: 10),
              _field(dateCtrl,    'التاريخ (YYYY-MM-DD)', AppColors.neonGold,   type: TextInputType.datetime),
              const SizedBox(height: 10),
              _field(notesCtrl,   'ملاحظات',              AppColors.textSecondary, maxLines: 2),
              const SizedBox(height: 16),
              if (isEdit) Row(children: [
                Expanded(child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonRed),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await _confirm('حذف المطابقة');
                    if (ok) { try { await ApiService.delete('/bank-reconciliations/${rec['id']}'); _load(); } catch (_) {} }
                  },
                  child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                )),
                const SizedBox(width: 10),
                Expanded(child: _saveBtn(ctx, isEdit, rec, bankCtrl, balanceCtrl, bookCtrl, dateCtrl, notesCtrl)),
              ]) else SizedBox(width: double.infinity,
                  child: _saveBtn(ctx, isEdit, rec, bankCtrl, balanceCtrl, bookCtrl, dateCtrl, notesCtrl)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _saveBtn(BuildContext ctx, bool isEdit, Map<String, dynamic>? rec,
      TextEditingController bankCtrl, TextEditingController balanceCtrl,
      TextEditingController bookCtrl,  TextEditingController dateCtrl,
      TextEditingController notesCtrl) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () async {
        final bank    = bankCtrl.text.trim();
        final bankBal = double.tryParse(balanceCtrl.text);
        final bookBal = double.tryParse(bookCtrl.text);
        if (bank.isEmpty || bankBal == null || bookBal == null) return;
        Navigator.pop(ctx);
        try {
          final body = {
            'bankName':    bank,
            'bankBalance': bankBal,
            'bookBalance': bookBal,
            if (dateCtrl.text.isNotEmpty)  'date':  dateCtrl.text.trim(),
            if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
          };
          if (isEdit) {
            await ApiService.patch('/bank-reconciliations/${rec!['id']}', data: body);
          } else {
            await ApiService.post('/bank-reconciliations', data: body);
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
          backgroundColor: AppColors.bgCard,
          title: Text(title),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonCyan,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'المطابقة البنكية'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد مطابقات بنكية', icon: Icons.account_balance_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _items[i] as Map<String, dynamic>;
                            final bankBal = r['bankBalance'] ?? 0;
                            final bookBal = r['bookBalance'] ?? 0;
                            final diff    = (bankBal as num) - (bookBal as num);
                            final matched = diff.abs() < 0.01;
                            return GestureDetector(
                              onLongPress: () => _showForm(r),
                              child: GlassCard(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(r['bankName'] ?? '--', style: AppText.h3,
                                          textDirection: TextDirection.rtl),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (matched ? AppColors.neonGreen : AppColors.neonRed)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(matched ? 'متطابق' : 'فرق: ${diff.toStringAsFixed(2)}',
                                            style: AppText.label.copyWith(
                                                color: matched ? AppColors.neonGreen : AppColors.neonRed)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('رصيد البنك: $bankBal ج.م', style: AppText.caption),
                                      Text('رصيد الدفاتر: $bookBal ج.م', style: AppText.caption),
                                    ],
                                  ),
                                  Text(r['date']?.toString().substring(0, 10) ?? '--',
                                      style: AppText.label),
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
