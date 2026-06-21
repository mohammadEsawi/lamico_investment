import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/sales_nav.dart';

class SalesSalesScreen extends StatefulWidget {
  const SalesSalesScreen({super.key});
  @override
  State<SalesSalesScreen> createState() => _SalesSalesScreenState();
}

class _SalesSalesScreenState extends State<SalesSalesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/sales/me');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['sales'] ?? data['data'] ?? []);
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

  void _showCreate() {
    final customerCtrl  = TextEditingController();
    final productCtrl   = TextEditingController();
    final qtyCtrl       = TextEditingController();
    final priceCtrl     = TextEditingController();
    final notesCtrl     = TextEditingController();
    XFile? imageFile;

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
                Text('تسجيل بيعة', style: AppText.h3),
                const SizedBox(height: 14),
                _field(customerCtrl, 'اسم العميل *',   AppColors.neonGold),
                const SizedBox(height: 10),
                _field(productCtrl,  'المنتج *',        AppColors.neonCyan),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(qtyCtrl,   'الكمية *',   AppColors.neonGreen, type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(priceCtrl, 'السعر *',    AppColors.neonPurple, type: TextInputType.number)),
                ]),
                const SizedBox(height: 10),
                _field(notesCtrl, 'ملاحظات', AppColors.textSecondary, maxLines: 2),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) ss(() => imageFile = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.neonGold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: imageFile != null
                            ? AppColors.neonGold
                            : AppColors.neonGold.withValues(alpha: 0.3))),
                    child: Row(textDirection: TextDirection.rtl, children: [
                      const Icon(Icons.image_outlined, color: AppColors.neonGold),
                      const SizedBox(width: 8),
                      Text(imageFile != null ? imageFile!.name : 'إرفاق صورة (اختياري)',
                          style: AppText.body.copyWith(
                              color: imageFile != null ? AppColors.textPrimary : AppColors.textSecondary)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      final customer = customerCtrl.text.trim();
                      final product  = productCtrl.text.trim();
                      final qty      = double.tryParse(qtyCtrl.text);
                      final price    = double.tryParse(priceCtrl.text);
                      if (customer.isEmpty || product.isEmpty || qty == null || price == null) return;
                      Navigator.pop(ctx);
                      try {
                        if (imageFile != null) {
                          final form = FormData.fromMap({
                            'customerName': customer,
                            'product':      product,
                            'quantity':     qty,
                            'price':        price,
                            if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                            'image': await MultipartFile.fromFile(
                                imageFile!.path, filename: imageFile!.name),
                          });
                          await ApiService.postMultipart('/sales', form);
                        } else {
                          await ApiService.post('/sales', data: {
                            'customerName': customer,
                            'product':      product,
                            'quantity':     qty,
                            'price':        price,
                            if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                          });
                        }
                        _load();
                      } catch (_) {}
                    },
                    child: const Text('تسجيل البيعة',
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

  Future<void> _delete(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('حذف البيعة'),
          content: const Text('هل تريد حذف هذا السجل؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(c, true),
                child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
          ],
        ),
      ),
    );
    if (ok == true) {
      try { await ApiService.delete('/sales/${s['id']}'); _load(); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const SalesNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGold,
        onPressed: _showCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'المبيعات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد مبيعات', icon: Icons.point_of_sale_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final s = _items[i] as Map<String, dynamic>;
                            final total = ((s['quantity'] ?? 0) as num) * ((s['price'] ?? 0) as num);
                            return GestureDetector(
                              onLongPress: () => _delete(s),
                              child: GlassCard(
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonGold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.point_of_sale, color: AppColors.neonGold),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s['customerName'] ?? s['customer']?['name'] ?? '--',
                                              style: AppText.h3, textDirection: TextDirection.rtl),
                                          Text(s['product'] ?? '--',
                                              style: AppText.caption, textDirection: TextDirection.rtl),
                                          Text(s['createdAt']?.toString().substring(0, 10) ?? '--',
                                              style: AppText.label),
                                        ],
                                      ),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text('${s['total'] ?? total} ج.م',
                                          style: AppText.h3.copyWith(color: AppColors.neonGold)),
                                      Text('× ${s['quantity'] ?? '--'}',
                                          style: AppText.caption),
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
