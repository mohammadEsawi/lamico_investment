import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerSparePartsScreen extends StatefulWidget {
  const EngineerSparePartsScreen({super.key});
  @override
  State<EngineerSparePartsScreen> createState() => _EngineerSparePartsScreenState();
}

class _EngineerSparePartsScreenState extends State<EngineerSparePartsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/spare-parts/');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['parts'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  void _showForm([Map<String, dynamic>? part]) {
    final isEdit = part != null;
    final nameCtrl     = TextEditingController(text: part?['name'] ?? '');
    final partNoCtrl   = TextEditingController(text: part?['partNumber'] ?? part?['code'] ?? '');
    final qtyCtrl      = TextEditingController(text: '${part?['quantity'] ?? part?['stock'] ?? ''}');
    final minQtyCtrl   = TextEditingController(text: '${part?['minQuantity'] ?? ''}');
    final unitCtrl     = TextEditingController(text: part?['unit'] ?? '');
    final supplierCtrl = TextEditingController(text: part?['supplier'] ?? '');
    final priceCtrl    = TextEditingController(text: '${part?['price'] ?? ''}');

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
              Text(isEdit ? 'تعديل قطعة الغيار' : 'إضافة قطعة غيار', style: AppText.h3),
              const SizedBox(height: 16),
              _field(nameCtrl,     'اسم القطعة *',     AppColors.neonGold),
              const SizedBox(height: 10),
              _field(partNoCtrl,   'رقم القطعة',       AppColors.neonCyan, type: TextInputType.text),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(qtyCtrl,    'الكمية *',  AppColors.neonGreen)),
                const SizedBox(width: 10),
                Expanded(child: _field(minQtyCtrl, 'حد المخزون', AppColors.neonRed)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(unitCtrl,   'الوحدة',   AppColors.neonCyan, type: TextInputType.text)),
                const SizedBox(width: 10),
                Expanded(child: _field(priceCtrl,  'السعر',    AppColors.neonPurple)),
              ]),
              const SizedBox(height: 10),
              _field(supplierCtrl, 'المورد',           AppColors.textSecondary, type: TextInputType.text),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final body = {
                        'name'       : name,
                        if (partNoCtrl.text.isNotEmpty)  'partNumber' : partNoCtrl.text.trim(),
                        if (qtyCtrl.text.isNotEmpty)     'quantity'   : int.tryParse(qtyCtrl.text) ?? 0,
                        if (minQtyCtrl.text.isNotEmpty)  'minQuantity': int.tryParse(minQtyCtrl.text) ?? 0,
                        if (unitCtrl.text.isNotEmpty)    'unit'       : unitCtrl.text.trim(),
                        if (supplierCtrl.text.isNotEmpty)'supplier'   : supplierCtrl.text.trim(),
                        if (priceCtrl.text.isNotEmpty)   'price'      : double.tryParse(priceCtrl.text) ?? 0,
                      };
                      if (isEdit) {
                        await ApiService.patch('/spare-parts/${part['id']}', data: body);
                      } else {
                        await ApiService.post('/spare-parts', data: body);
                      }
                      _load();
                    } catch (_) {}
                  },
                  child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة',
                      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> part) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('حذف قطعة الغيار'),
          content: Text('هل تريد حذف "${part['name'] ?? '--'}"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try { await ApiService.delete('/spare-parts/${part['id']}'); _load(); } catch (_) {}
    }
  }

  Widget _field(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.number}) =>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGold,
        onPressed: _showForm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'قطع الغيار'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد قطع غيار', icon: Icons.settings_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final p = _items[i];
                            final qty = p['quantity'] ?? p['stock'] ?? 0;
                            final minQty = p['minQuantity'] ?? 5;
                            final lowStock = (qty is num) && (minQty is num) && qty < minQty;
                            return GestureDetector(
                              onTap: () => _showForm(p as Map<String, dynamic>),
                              onLongPress: () => _delete(p as Map<String, dynamic>),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (lowStock ? AppColors.neonRed : AppColors.neonGold)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.settings,
                                          color: lowStock ? AppColors.neonRed : AppColors.neonGold),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'] ?? '--', style: AppText.h3,
                                              textDirection: TextDirection.rtl),
                                          Text(p['partNumber'] ?? p['code'] ?? '--',
                                              style: AppText.caption, textDirection: TextDirection.rtl),
                                          if (p['supplier'] != null)
                                            Text('المورد: ${p['supplier']}',
                                                style: AppText.label.copyWith(color: AppColors.textSecondary),
                                                textDirection: TextDirection.rtl),
                                        ],
                                      ),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text('$qty ${p['unit'] ?? ''}',
                                          style: AppText.h3.copyWith(
                                              color: lowStock ? AppColors.neonRed : AppColors.neonGreen)),
                                      if (lowStock)
                                        Text('مخزون منخفض',
                                            style: AppText.label.copyWith(color: AppColors.neonRed)),
                                    ]),
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
