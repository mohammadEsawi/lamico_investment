import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminShiftsScreen extends StatefulWidget {
  const AdminShiftsScreen({super.key});
  @override
  State<AdminShiftsScreen> createState() => _AdminShiftsScreenState();
}

class _AdminShiftsScreenState extends State<AdminShiftsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/shifts/');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['shifts'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  void _showAddShift() {
    final nameCtrl  = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl   = TextEditingController();
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
            Text('إضافة وردية', style: AppText.h2, textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            _field(nameCtrl, 'اسم الوردية'),
            const SizedBox(height: 10),
            _field(startCtrl, 'وقت البداية (مثال: 08:00)'),
            const SizedBox(height: 10),
            _field(endCtrl, 'وقت النهاية (مثال: 16:00)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    await ApiService.post('/shifts/', data: {
                      'name': nameCtrl.text.trim(),
                      'startTime': startCtrl.text.trim(),
                      'endTime': endCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (_) {}
                },
                child: const Text('إضافة', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: TextField(
      controller: ctrl,
      textAlign: TextAlign.right,
      style: AppText.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint, hintStyle: AppText.body, border: InputBorder.none),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonPurple,
        onPressed: _showAddShift,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الورديات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد ورديات', icon: Icons.schedule)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _x) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final s = _items[i];
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonPurple.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.schedule, color: AppColors.neonPurple),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['name'] ?? '--', style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text(
                                          '${s['startTime'] ?? '--'} - ${s['endTime'] ?? '--'}',
                                          style: AppText.caption,
                                          textDirection: TextDirection.rtl,
                                        ),
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
