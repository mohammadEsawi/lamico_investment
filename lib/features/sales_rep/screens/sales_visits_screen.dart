import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/sales_nav.dart';

class SalesVisitsScreen extends StatefulWidget {
  const SalesVisitsScreen({super.key});
  @override
  State<SalesVisitsScreen> createState() => _SalesVisitsScreenState();
}

class _SalesVisitsScreenState extends State<SalesVisitsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/sales-rep/visits');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['visits'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
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
            Text('تسجيل زيارة', style: AppText.h2, textDirection: TextDirection.rtl),
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
                  hintText: 'ملاحظات الزيارة',
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
                  backgroundColor: AppColors.neonGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    await ApiService.post('/sales-rep/visits', data: {'notes': notesCtrl.text.trim()});
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (_) {}
                },
                child: const Text('تسجيل الزيارة', style: TextStyle(fontFamily: 'Cairo')),
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
      bottomNavigationBar: const SalesNav(selectedIndex: 3),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGold,
        onPressed: _showAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'زيارات العملاء'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد زيارات', icon: Icons.directions_car_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final v = _items[i];
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.directions_car, color: AppColors.neonGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v['customer']?['name'] ?? v['customerName'] ?? '--',
                                            style: AppText.h3, textDirection: TextDirection.rtl),
                                        Text(v['notes'] ?? '--',
                                            style: AppText.caption, textDirection: TextDirection.rtl),
                                        Text(v['visitDate']?.toString().substring(0, 10) ?? '--',
                                            style: AppText.label),
                                      ],
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
