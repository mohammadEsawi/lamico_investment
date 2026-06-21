import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/sales_nav.dart';

class SalesTargetsScreen extends StatefulWidget {
  const SalesTargetsScreen({super.key});
  @override
  State<SalesTargetsScreen> createState() => _SalesTargetsScreenState();
}

class _SalesTargetsScreenState extends State<SalesTargetsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/sales-rep/targets');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['targets'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Widget _field(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.text}) =>
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

  void _showCreate() {
    final periodCtrl   = TextEditingController();
    final targetCtrl   = TextEditingController();
    final achievedCtrl = TextEditingController();

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
            Text('هدف جديد', style: AppText.h3),
            const SizedBox(height: 14),
            _field(periodCtrl,   'الفترة (مثال: 2025-06)',  AppColors.neonGold),
            const SizedBox(height: 10),
            _field(targetCtrl,   'مبلغ الهدف *',            AppColors.neonGreen, type: TextInputType.number),
            const SizedBox(height: 10),
            _field(achievedCtrl, 'المحقق (اختياري)',        AppColors.neonCyan,  type: TextInputType.number),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  final target = double.tryParse(targetCtrl.text);
                  if (target == null) return;
                  Navigator.pop(ctx);
                  try {
                    await ApiService.post('/sales-rep/targets', data: {
                      'targetAmount': target,
                      if (periodCtrl.text.isNotEmpty)   'period':         periodCtrl.text.trim(),
                      if (achievedCtrl.text.isNotEmpty)
                        'achievedAmount': double.tryParse(achievedCtrl.text) ?? 0,
                    });
                    _load();
                  } catch (_) {}
                },
                child: const Text('إضافة هدف',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showUpdateAchieved(Map<String, dynamic> t) {
    final achievedCtrl = TextEditingController(
        text: '${t['achievedAmount'] ?? t['achieved'] ?? ''}');

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
            Text('تحديث المحقق — ${t['period'] ?? ''}', style: AppText.h3),
            const SizedBox(height: 14),
            _field(achievedCtrl, 'المبلغ المحقق *', AppColors.neonGreen, type: TextInputType.number),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  final achieved = double.tryParse(achievedCtrl.text);
                  if (achieved == null) return;
                  Navigator.pop(ctx);
                  try {
                    await ApiService.patch('/sales-rep/targets/${t['id']}',
                        data: {'achievedAmount': achieved});
                    _load();
                  } catch (_) {}
                },
                child: const Text('تحديث',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
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
      bottomNavigationBar: const SalesNav(selectedIndex: 4),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGold,
        onPressed: _showCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'أهداف المبيعات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد أهداف محددة', icon: Icons.flag_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final t = _items[i] as Map<String, dynamic>;
                            final target   = (t['targetAmount']   ?? t['target']   ?? 0) as num;
                            final achieved = (t['achievedAmount'] ?? t['achieved'] ?? 0) as num;
                            final pct = target > 0 ? (achieved / target).clamp(0.0, 1.0) : 0.0;
                            return GestureDetector(
                              onLongPress: () => _showUpdateAchieved(t),
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      textDirection: TextDirection.rtl,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(t['period'] ?? t['month'] ?? '--',
                                            style: AppText.h3, textDirection: TextDirection.rtl),
                                        Text('${(pct * 100).toStringAsFixed(0)}%',
                                            style: AppText.h3.copyWith(
                                                color: pct >= 1.0 ? AppColors.neonGreen : AppColors.neonGold)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct.toDouble(),
                                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          pct >= 1.0 ? AppColors.neonGreen : AppColors.neonGold,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      textDirection: TextDirection.rtl,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('الهدف: $target ج.م', style: AppText.caption),
                                        Text('المحقق: $achieved ج.م', style: AppText.caption),
                                      ],
                                    ),
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
