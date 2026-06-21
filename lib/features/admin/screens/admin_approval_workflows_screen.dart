import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminApprovalWorkflowsScreen extends StatefulWidget {
  const AdminApprovalWorkflowsScreen({super.key});
  @override
  State<AdminApprovalWorkflowsScreen> createState() => _AdminApprovalWorkflowsScreenState();
}

class _AdminApprovalWorkflowsScreenState extends State<AdminApprovalWorkflowsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/approval-workflows');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['workflows'] ?? data['data'] ?? []);
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

  void _showForm([Map<String, dynamic>? wf]) {
    final isEdit     = wf != null;
    final nameCtrl   = TextEditingController(text: wf?['name'] ?? '');
    final entityCtrl = TextEditingController(text: wf?['entityType'] ?? '');
    final stepsCtrl  = TextEditingController(text: wf?['steps']?.toString() ?? '');
    final notesCtrl  = TextEditingController(text: wf?['notes'] ?? '');
    bool isActive    = wf?['isActive'] ?? true;

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
              Text(isEdit ? 'تعديل سير الموافقة' : 'سير موافقة جديد', style: AppText.h3),
              const SizedBox(height: 14),
              _field(nameCtrl,   'اسم السير *',     AppColors.neonGreen),
              const SizedBox(height: 10),
              _field(entityCtrl, 'نوع الكيان',       AppColors.neonCyan),
              const SizedBox(height: 10),
              _field(stepsCtrl,  'الخطوات / الأدوار', AppColors.neonPurple, maxLines: 2),
              const SizedBox(height: 10),
              _field(notesCtrl,  'ملاحظات',          AppColors.textSecondary, maxLines: 2),
              const SizedBox(height: 10),
              Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('نشط', style: AppText.body),
                  Switch(
                    value: isActive,
                    onChanged: (v) => ss(() => isActive = v),
                    activeThumbColor: AppColors.neonGreen,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isEdit) Row(children: [
                Expanded(child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonRed),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await _confirm('حذف سير الموافقة');
                    if (ok) { try { await ApiService.delete('/approval-workflows/${wf['id']}'); _load(); } catch (_) {} }
                  },
                  child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                )),
                const SizedBox(width: 10),
                Expanded(child: _saveBtn(ctx, isEdit, wf, nameCtrl, entityCtrl, stepsCtrl, notesCtrl, isActive)),
              ]) else SizedBox(width: double.infinity,
                  child: _saveBtn(ctx, isEdit, wf, nameCtrl, entityCtrl, stepsCtrl, notesCtrl, isActive)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _saveBtn(BuildContext ctx, bool isEdit, Map<String, dynamic>? wf,
      TextEditingController nameCtrl,   TextEditingController entityCtrl,
      TextEditingController stepsCtrl,  TextEditingController notesCtrl,
      bool isActive) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () async {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;
        Navigator.pop(ctx);
        try {
          final body = {
            'name': name, 'isActive': isActive,
            if (entityCtrl.text.isNotEmpty) 'entityType': entityCtrl.text.trim(),
            if (stepsCtrl.text.isNotEmpty)  'steps':      stepsCtrl.text.trim(),
            if (notesCtrl.text.isNotEmpty)  'notes':      notesCtrl.text.trim(),
          };
          if (isEdit) {
            await ApiService.patch('/approval-workflows/${wf!['id']}', data: body);
          } else {
            await ApiService.post('/approval-workflows', data: body);
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
        backgroundColor: AppColors.neonGreen,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'سير الموافقات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد سير موافقات', icon: Icons.account_tree_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final w = _items[i] as Map<String, dynamic>;
                            final active = w['isActive'] ?? true;
                            return GestureDetector(
                              onLongPress: () => _showForm(w),
                              child: GlassCard(
                                child: Row(textDirection: TextDirection.rtl, children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppColors.neonGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.account_tree, color: AppColors.neonGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(w['name'] ?? '--', style: AppText.h3,
                                          textDirection: TextDirection.rtl),
                                      Text(w['entityType'] ?? '--', style: AppText.caption,
                                          textDirection: TextDirection.rtl),
                                    ],
                                  )),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: (active ? AppColors.neonGreen : AppColors.textSecondary)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(active ? 'نشط' : 'معطّل',
                                        style: AppText.label.copyWith(
                                            color: active ? AppColors.neonGreen : AppColors.textSecondary)),
                                  ),
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
