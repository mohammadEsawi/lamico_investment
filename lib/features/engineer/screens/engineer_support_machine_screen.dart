import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerSupportMachineScreen extends StatefulWidget {
  const EngineerSupportMachineScreen({super.key});
  @override
  State<EngineerSupportMachineScreen> createState() => _EngineerSupportMachineScreenState();
}

class _EngineerSupportMachineScreenState extends State<EngineerSupportMachineScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/support-machine-readings/mine');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['readings'] ?? data['data'] ?? []);
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

  void _showAdd() {
    final machineCtrl = TextEditingController();
    final valueCtrl   = TextEditingController();
    final unitCtrl    = TextEditingController();
    final notesCtrl   = TextEditingController();

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
            Text('قراءة آلة داعمة', style: AppText.h3),
            const SizedBox(height: 14),
            _field(machineCtrl, 'اسم الآلة *',   AppColors.neonOrange),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(valueCtrl, 'القراءة *', AppColors.neonGreen, type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _field(unitCtrl,  'الوحدة',   AppColors.neonCyan)),
            ]),
            const SizedBox(height: 10),
            _field(notesCtrl, 'ملاحظات', AppColors.textSecondary, maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  final machine = machineCtrl.text.trim();
                  final value   = double.tryParse(valueCtrl.text);
                  if (machine.isEmpty || value == null) return;
                  Navigator.pop(ctx);
                  try {
                    await ApiService.post('/support-machine-readings', data: {
                      'machineName': machine,
                      'value':       value,
                      if (unitCtrl.text.isNotEmpty)  'unit':  unitCtrl.text.trim(),
                      if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                    });
                    _load();
                  } catch (_) {}
                },
                child: const Text('تسجيل القراءة',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('حذف القراءة'),
          content: const Text('هل تريد حذف هذه القراءة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(c, true),
                child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
          ],
        ),
      ),
    );
    if (ok == true) {
      try { await ApiService.delete('/support-machine-readings/${item['id']}'); _load(); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonOrange,
        onPressed: _showAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'قراءات الآلات الداعمة'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(
                        message: 'لا توجد قراءات', icon: Icons.speed_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _items[i] as Map<String, dynamic>;
                            return GestureDetector(
                              onLongPress: () => _delete(r),
                              child: GlassCard(
                                child: Row(textDirection: TextDirection.rtl, children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppColors.neonOrange.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.speed, color: AppColors.neonOrange),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['machineName'] ?? r['machine'] ?? '--',
                                          style: AppText.h3, textDirection: TextDirection.rtl),
                                      Text(r['notes'] ?? '--', style: AppText.caption,
                                          textDirection: TextDirection.rtl),
                                      Text(r['createdAt']?.toString().substring(0, 10) ?? '--',
                                          style: AppText.label),
                                    ],
                                  )),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('${r['value'] ?? '--'}',
                                        style: AppText.h3.copyWith(color: AppColors.neonOrange)),
                                    Text(r['unit'] ?? '', style: AppText.caption),
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
