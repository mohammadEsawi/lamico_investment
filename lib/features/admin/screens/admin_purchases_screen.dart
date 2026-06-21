import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminPurchasesScreen extends StatefulWidget {
  const AdminPurchasesScreen({super.key});
  @override
  State<AdminPurchasesScreen> createState() => _AdminPurchasesScreenState();
}

class _AdminPurchasesScreenState extends State<AdminPurchasesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/purchases/all');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['purchases'] ?? data['data'] ?? []);
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

  void _showForm([Map<String, dynamic>? purchase]) {
    final isEdit       = purchase != null;
    final supplierCtrl = TextEditingController(text: purchase?['supplierName'] ?? purchase?['supplier']?['name'] ?? '');
    final itemCtrl     = TextEditingController(text: purchase?['itemName'] ?? purchase?['item'] ?? '');
    final qtyCtrl      = TextEditingController(text: '${purchase?['quantity'] ?? ''}');
    final priceCtrl    = TextEditingController(text: '${purchase?['unitPrice'] ?? purchase?['price'] ?? ''}');
    final dateCtrl     = TextEditingController(text: purchase?['purchaseDate']?.toString().substring(0, 10) ?? '');
    final notesCtrl    = TextEditingController(text: purchase?['notes'] ?? '');

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
              Text(isEdit ? 'تعديل الشراء' : 'شراء جديد', style: AppText.h3),
              const SizedBox(height: 14),
              _field(supplierCtrl, 'المورد *',            AppColors.neonGold),
              const SizedBox(height: 10),
              _field(itemCtrl,     'الصنف *',             AppColors.neonCyan),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(qtyCtrl,   'الكمية *',    AppColors.neonGreen,  type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _field(priceCtrl, 'سعر الوحدة *', AppColors.neonPurple, type: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              _field(dateCtrl,  'تاريخ الشراء',         AppColors.neonOrange, type: TextInputType.datetime),
              const SizedBox(height: 10),
              _field(notesCtrl, 'ملاحظات',               AppColors.textSecondary, maxLines: 2),
              const SizedBox(height: 16),
              if (isEdit) Row(children: [
                Expanded(child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonRed),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await _confirm('حذف الشراء');
                    if (ok) { try { await ApiService.delete('/purchases/${purchase['id']}'); _load(); } catch (_) {} }
                  },
                  child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                )),
                const SizedBox(width: 10),
                Expanded(child: _saveBtn(ctx, isEdit, purchase, supplierCtrl, itemCtrl, qtyCtrl, priceCtrl, dateCtrl, notesCtrl)),
              ]) else SizedBox(width: double.infinity,
                  child: _saveBtn(ctx, isEdit, purchase, supplierCtrl, itemCtrl, qtyCtrl, priceCtrl, dateCtrl, notesCtrl)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _saveBtn(BuildContext ctx, bool isEdit, Map<String, dynamic>? purchase,
      TextEditingController supplierCtrl, TextEditingController itemCtrl,
      TextEditingController qtyCtrl,     TextEditingController priceCtrl,
      TextEditingController dateCtrl,    TextEditingController notesCtrl) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () async {
        final supplier = supplierCtrl.text.trim();
        final item     = itemCtrl.text.trim();
        final qty      = double.tryParse(qtyCtrl.text);
        final price    = double.tryParse(priceCtrl.text);
        if (supplier.isEmpty || item.isEmpty || qty == null || price == null) return;
        Navigator.pop(ctx);
        try {
          final body = {
            'supplierName': supplier, 'itemName': item,
            'quantity': qty, 'unitPrice': price,
            if (dateCtrl.text.isNotEmpty)  'purchaseDate': dateCtrl.text.trim(),
            if (notesCtrl.text.isNotEmpty) 'notes':        notesCtrl.text.trim(),
          };
          if (isEdit) {
            await ApiService.put('/purchases/${purchase!['id']}', data: body);
          } else {
            await ApiService.post('/purchases', data: body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGold,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'المشتريات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد مشتريات', icon: Icons.shopping_cart_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final p = _items[i] as Map<String, dynamic>;
                            final total = ((p['quantity'] ?? 0) as num) *
                                ((p['unitPrice'] ?? p['price'] ?? 0) as num);
                            return GestureDetector(
                              onLongPress: () => _showForm(p),
                              child: GlassCard(
                                child: Row(textDirection: TextDirection.rtl, children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppColors.neonGold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.shopping_cart, color: AppColors.neonGold),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['itemName'] ?? p['item'] ?? '--',
                                          style: AppText.h3, textDirection: TextDirection.rtl),
                                      Text(p['supplierName'] ?? p['supplier']?['name'] ?? '--',
                                          style: AppText.caption, textDirection: TextDirection.rtl),
                                      Text(p['purchaseDate']?.toString().substring(0, 10) ?? '--',
                                          style: AppText.label),
                                    ],
                                  )),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('${p['total'] ?? total.toStringAsFixed(0)} ج.م',
                                        style: AppText.h3.copyWith(color: AppColors.neonGold)),
                                    Text('× ${p['quantity'] ?? '--'}', style: AppText.caption),
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
