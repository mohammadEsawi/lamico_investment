import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/accountant_nav.dart';

class AccountantExpensesScreen extends StatefulWidget {
  const AccountantExpensesScreen({super.key});
  @override
  State<AccountantExpensesScreen> createState() => _AccountantExpensesScreenState();
}

class _AccountantExpensesScreenState extends State<AccountantExpensesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/expenses');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['expenses'] ?? data['data'] ?? []);
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
    final titleCtrl    = TextEditingController();
    final categoryCtrl = TextEditingController();
    final amountCtrl   = TextEditingController();
    final dateCtrl     = TextEditingController();
    final descCtrl     = TextEditingController();

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
              Text('مصروف جديد', style: AppText.h3),
              const SizedBox(height: 14),
              _field(titleCtrl,    'العنوان *',       AppColors.neonRed),
              const SizedBox(height: 10),
              _field(categoryCtrl, 'الفئة',           AppColors.neonOrange),
              const SizedBox(height: 10),
              _field(amountCtrl,   'المبلغ *',        AppColors.neonGreen, type: TextInputType.number),
              const SizedBox(height: 10),
              _field(dateCtrl,     'التاريخ (YYYY-MM-DD)', AppColors.neonCyan, type: TextInputType.datetime),
              const SizedBox(height: 10),
              _field(descCtrl,     'الوصف',           AppColors.textSecondary, maxLines: 2),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    final title  = titleCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text);
                    if (title.isEmpty || amount == null) return;
                    Navigator.pop(ctx);
                    try {
                      await ApiService.post('/expenses', data: {
                        'title':  title,
                        'amount': amount,
                        if (categoryCtrl.text.isNotEmpty) 'category':    categoryCtrl.text.trim(),
                        if (dateCtrl.text.isNotEmpty)     'date':        dateCtrl.text.trim(),
                        if (descCtrl.text.isNotEmpty)     'description': descCtrl.text.trim(),
                      });
                      _load();
                    } catch (_) {}
                  },
                  child: const Text('إضافة مصروف',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showActions(Map<String, dynamic> e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(e['title'] ?? e['description'] ?? '--', style: AppText.h3),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: AppColors.neonGreen),
              title: const Text('اعتماد المصروف', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.patch('/expenses/${e['id']}/approve', data: {});
                  _load();
                } catch (_) {}
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.neonRed),
              title: const Text('حذف المصروف', style: TextStyle(fontFamily: 'Cairo', color: AppColors.neonRed)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: AlertDialog(
                      backgroundColor: AppColors.bgCard,
                      title: const Text('حذف المصروف'),
                      content: const Text('هل تريد حذف هذا المصروف؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                        TextButton(onPressed: () => Navigator.pop(c, true),
                            child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
                      ],
                    ),
                  ),
                );
                if (ok == true) {
                  try { await ApiService.delete('/expenses/${e['id']}'); _load(); } catch (_) {}
                }
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AccountantNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonRed,
        onPressed: _showCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'المصروفات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد مصروفات', icon: Icons.money_off_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final e = _items[i] as Map<String, dynamic>;
                            final approved = e['approvedAt'] != null || e['isApproved'] == true;
                            return GestureDetector(
                              onLongPress: () => _showActions(e),
                              child: GlassCard(
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonRed.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.money_off, color: AppColors.neonRed),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e['title'] ?? e['description'] ?? '--',
                                              style: AppText.h3, textDirection: TextDirection.rtl),
                                          Text(e['category'] ?? e['type'] ?? '--',
                                              style: AppText.caption, textDirection: TextDirection.rtl),
                                          Text(e['date']?.toString().substring(0, 10) ?? '--',
                                              style: AppText.label),
                                        ],
                                      ),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text('${e['amount'] ?? '--'} ج.م',
                                          style: AppText.h3.copyWith(color: AppColors.neonRed)),
                                      if (approved)
                                        const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 16),
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
