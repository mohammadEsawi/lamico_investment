import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminCostAnalysisScreen extends StatefulWidget {
  const AdminCostAnalysisScreen({super.key});
  @override
  State<AdminCostAnalysisScreen> createState() => _AdminCostAnalysisScreenState();
}

class _AdminCostAnalysisScreenState extends State<AdminCostAnalysisScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/cost-analysis');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['analyses'] ?? data['data'] ?? []);
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

  void _showForm([Map<String, dynamic>? item]) {
    final isEdit      = item != null;
    final titleCtrl   = TextEditingController(text: item?['title'] ?? item?['name'] ?? '');
    final categoryCtrl = TextEditingController(text: item?['category'] ?? '');
    final totalCtrl   = TextEditingController(text: '${item?['totalCost'] ?? item?['cost'] ?? ''}');
    final periodCtrl  = TextEditingController(text: item?['period'] ?? '');
    final notesCtrl   = TextEditingController(text: item?['notes'] ?? '');

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
            Text(isEdit ? 'تعديل التحليل' : 'تحليل تكلفة جديد', style: AppText.h3),
            const SizedBox(height: 14),
            _field(titleCtrl,    'العنوان *',      AppColors.neonPurple),
            const SizedBox(height: 10),
            _field(categoryCtrl, 'الفئة',          AppColors.neonCyan),
            const SizedBox(height: 10),
            _field(totalCtrl,    'إجمالي التكلفة *', AppColors.neonRed, type: TextInputType.number),
            const SizedBox(height: 10),
            _field(periodCtrl,   'الفترة',          AppColors.neonGold),
            const SizedBox(height: 10),
            _field(notesCtrl,    'ملاحظات',         AppColors.textSecondary, maxLines: 2),
            const SizedBox(height: 16),
            if (isEdit) Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonRed),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await _confirm('حذف التحليل');
                  if (ok) { try { await ApiService.delete('/cost-analysis/${item['id']}'); _load(); } catch (_) {} }
                },
                child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
              )),
              const SizedBox(width: 10),
              Expanded(child: _saveBtn(ctx, isEdit, item, titleCtrl, categoryCtrl, totalCtrl, periodCtrl, notesCtrl)),
            ]) else SizedBox(width: double.infinity,
                child: _saveBtn(ctx, isEdit, item, titleCtrl, categoryCtrl, totalCtrl, periodCtrl, notesCtrl)),
          ]),
        ),
      ),
    );
  }

  Widget _saveBtn(BuildContext ctx, bool isEdit, Map<String, dynamic>? item,
      TextEditingController titleCtrl,    TextEditingController categoryCtrl,
      TextEditingController totalCtrl,    TextEditingController periodCtrl,
      TextEditingController notesCtrl) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () async {
        final title = titleCtrl.text.trim();
        final total = double.tryParse(totalCtrl.text);
        if (title.isEmpty || total == null) return;
        Navigator.pop(ctx);
        try {
          final body = {
            'title': title, 'totalCost': total,
            if (categoryCtrl.text.isNotEmpty) 'category': categoryCtrl.text.trim(),
            if (periodCtrl.text.isNotEmpty)   'period':   periodCtrl.text.trim(),
            if (notesCtrl.text.isNotEmpty)    'notes':    notesCtrl.text.trim(),
          };
          if (isEdit) {
            await ApiService.patch('/cost-analysis/${item!['id']}', data: body);
          } else {
            await ApiService.post('/cost-analysis', data: body);
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
        backgroundColor: AppColors.neonPurple,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'تحليل التكاليف'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد تحليلات تكلفة', icon: Icons.analytics_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final a = _items[i] as Map<String, dynamic>;
                            return GestureDetector(
                              onLongPress: () => _showForm(a),
                              child: GlassCard(
                                child: Row(textDirection: TextDirection.rtl, children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppColors.neonPurple.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.analytics, color: AppColors.neonPurple),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a['title'] ?? a['name'] ?? '--',
                                          style: AppText.h3, textDirection: TextDirection.rtl),
                                      Text(a['category'] ?? '--',
                                          style: AppText.caption, textDirection: TextDirection.rtl),
                                      Text(a['period'] ?? '--', style: AppText.label),
                                    ],
                                  )),
                                  Text('${a['totalCost'] ?? a['cost'] ?? '--'} ج.م',
                                      style: AppText.h3.copyWith(color: AppColors.neonPurple)),
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
