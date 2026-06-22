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

class EngineerRawMaterialAlertsScreen extends StatefulWidget {
  const EngineerRawMaterialAlertsScreen({super.key});
  @override
  State<EngineerRawMaterialAlertsScreen> createState() =>
      _EngineerRawMaterialAlertsScreenState();
}

class _EngineerRawMaterialAlertsScreenState
    extends State<EngineerRawMaterialAlertsScreen> {
  List<dynamic> _materials = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/raw-material-alerts');
      final data = res.data;
      setState(() {
        _materials = data is List ? data : (data['materials'] ?? data['data'] ?? []);
        AppDate.sortDesc(_materials, field: 'updatedAt');
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _updateStock(Map<String, dynamic> mat) async {
    final stockCtrl = TextEditingController(text: '${mat['currentStock'] ?? ''}');
    final notesCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('تحديث المخزون — ${mat['name']}', style: AppText.h3,
                textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            TextField(
              controller: stockCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('الكمية الحالية (${mat['unit'] ?? ''})'),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: _dec('ملاحظات'),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ApiService.patch('/raw-material-alerts/${mat['id']}/stock',
                        data: {
                          'currentStock': double.tryParse(stockCtrl.text) ?? 0,
                          if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text,
                        });
                    _load();
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('فشل التحديث'),
                        backgroundColor: AppColors.neonRed));
                  }
                },
                child: const Text('حفظ', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _setThreshold(Map<String, dynamic> mat) async {
    final ctrl = TextEditingController(text: '${mat['alertThreshold'] ?? ''}');
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('تحديد حد التنبيه — ${mat['name']}', style: AppText.h3),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('حد التنبيه (${mat['unit'] ?? ''})'),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGold,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ApiService.post('/raw-material-alerts/threshold', data: {
                      'materialId': mat['id'],
                      'threshold': double.tryParse(ctrl.text) ?? 0,
                    });
                    _load();
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('فشل التحديث'),
                        backgroundColor: AppColors.neonRed));
                  }
                },
                child: const Text('حفظ', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final lowCount = _materials.where((m) => m['isLowStock'] == true).length;
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 4),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'تنبيهات المواد الخام'),
          if (!_loading && _materials.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  _summaryChip('${_materials.length} مادة', AppColors.neonCyan),
                  const SizedBox(width: 8),
                  if (lowCount > 0)
                    _summaryChip('$lowCount مخزون منخفض ⚠', AppColors.neonRed),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _materials.isEmpty
                    ? const Center(
                        child: Text('لا توجد مواد', textDirection: TextDirection.rtl))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _materials.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final m = _materials[i];
                            final isLow = m['isLowStock'] == true;
                            final stockColor =
                                isLow ? AppColors.neonRed : AppColors.neonGreen;
                            return GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          if (isLow)
                                            const Icon(Icons.warning_amber,
                                                color: AppColors.neonRed, size: 18),
                                          if (isLow) const SizedBox(width: 6),
                                          Text(m['name'] ?? '--',
                                              style: AppText.h3,
                                              textDirection: TextDirection.rtl),
                                        ],
                                      ),
                                      Row(children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              color: AppColors.neonCyan, size: 20),
                                          tooltip: 'تحديث المخزون',
                                          onPressed: () => _updateStock(
                                              m as Map<String, dynamic>),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.notifications_outlined,
                                              color: AppColors.neonGold, size: 20),
                                          tooltip: 'تحديد الحد',
                                          onPressed: () => _setThreshold(
                                              m as Map<String, dynamic>),
                                        ),
                                      ]),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Text('المخزون: ',
                                          style: AppText.caption,
                                          textDirection: TextDirection.rtl),
                                      Text(
                                        '${m['currentStock'] ?? '--'} ${m['unit'] ?? ''}',
                                        style: AppText.body.copyWith(color: stockColor),
                                        textDirection: TextDirection.rtl,
                                      ),
                                      const SizedBox(width: 16),
                                      Text('الحد: ',
                                          style: AppText.caption,
                                          textDirection: TextDirection.rtl),
                                      Text(
                                        m['alertThreshold'] != null
                                            ? '${m['alertThreshold']} ${m['unit'] ?? ''}'
                                            : 'لم يحدد',
                                        style: AppText.body.copyWith(
                                            color: m['alertThreshold'] != null
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                  if (m['updatedAt'] != null || m['createdAt'] != null)
                                    Text(
                                      AppDate.format(m['updatedAt'] ?? m['createdAt']),
                                      style: AppText.label.copyWith(color: AppColors.textSecondary),
                                      textDirection: TextDirection.rtl,
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

  Widget _summaryChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: AppText.label.copyWith(color: color),
            textDirection: TextDirection.rtl),
      );
}
