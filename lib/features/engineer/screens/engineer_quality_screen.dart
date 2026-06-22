import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerQualityScreen extends StatefulWidget {
  const EngineerQualityScreen({super.key});
  @override
  State<EngineerQualityScreen> createState() => _EngineerQualityScreenState();
}

class _EngineerQualityScreenState extends State<EngineerQualityScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/quality-checks/me');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['inspections'] ?? data['data'] ?? []);
        AppDate.sortDesc(_items);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  void _showResolve(Map<String, dynamic> q) {
    final resolutionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
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
            Text('حل المشكلة', style: AppText.h3),
            const SizedBox(height: 4),
            Text(q['title'] ?? q['machine']?['name'] ?? 'فحص جودة',
                style: AppText.caption, textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            TextField(
              controller: resolutionCtrl,
              maxLines: 2,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'الحل المتخذ',
                filled: true, fillColor: AppColors.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                filled: true, fillColor: AppColors.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ApiService.patch('/quality-checks/${q['id']}/resolve', data: {
                      'resolution': resolutionCtrl.text.trim(),
                      if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                    });
                    _load();
                  } catch (_) {}
                },
                child: const Text('تأكيد الحل',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('حذف فحص الجودة'),
          content: const Text('هل تريد حذف هذا الفحص نهائياً؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: AppColors.neonRed)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.delete('/quality-checks/${q['id']}');
        _load();
      } catch (_) {}
    }
  }

  void _showAdd() {
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('فحص جودة جديد', style: AppText.h2, textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: TextField(
                controller: notesCtrl,
                textAlign: TextAlign.right,
                maxLines: 3,
                style: AppText.body.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'ملاحظات الفحص',
                  hintStyle: AppText.body,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    await ApiService.post('/quality-checks', data: {'description': notesCtrl.text.trim()});
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (_) {}
                },
                child: const Text('إضافة فحص', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGreen,
        onPressed: _showAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'فحص الجودة'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد فحوصات جودة', icon: Icons.verified_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final q = _items[i];
                            final passed = q['passed'] as bool? ?? true;
                            final resolved = q['resolvedAt'] != null || q['isResolved'] == true;
                            return GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (passed ? AppColors.neonGreen : AppColors.neonRed)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                                          color: passed ? AppColors.neonGreen : AppColors.neonRed,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(q['title'] ?? q['machine']?['name'] ?? 'فحص جودة',
                                                style: AppText.h3,
                                                textDirection: TextDirection.rtl),
                                            Text(q['notes'] ?? q['description'] ?? '--',
                                                style: AppText.caption,
                                                textDirection: TextDirection.rtl),
                                            Text(AppDate.format(q['createdAt']),
                                                style: AppText.label.copyWith(color: AppColors.textSecondary),
                                                textDirection: TextDirection.rtl),
                                          ],
                                        ),
                                      ),
                                      Text(passed ? 'ناجح' : 'فاشل',
                                          style: AppText.label.copyWith(
                                              color: passed ? AppColors.neonGreen : AppColors.neonRed)),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppColors.neonRed, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _delete(q as Map<String, dynamic>),
                                      ),
                                    ],
                                  ),
                                  if (!passed && !resolved)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () => _showResolve(q as Map<String, dynamic>),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.neonGreen),
                                          child: const Text('حل المشكلة',
                                              style: TextStyle(fontFamily: 'Cairo')),
                                        ),
                                      ),
                                    ),
                                  if (resolved)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.neonGreen.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('تم الحل',
                                            style: AppText.label.copyWith(color: AppColors.neonGreen)),
                                      ),
                                    ),
                                ],
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
