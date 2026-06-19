import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerMaintenanceScreen extends StatefulWidget {
  const EngineerMaintenanceScreen({super.key});
  @override
  State<EngineerMaintenanceScreen> createState() => _EngineerMaintenanceScreenState();
}

class _EngineerMaintenanceScreenState extends State<EngineerMaintenanceScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/maintenance/me');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['requests'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _priorityColor(String? p) {
    switch (p) {
      case 'HIGH':   return AppColors.neonRed;
      case 'MEDIUM': return AppColors.neonGold;
      case 'LOW':    return AppColors.neonGreen;
      default:       return AppColors.textSecondary;
    }
  }

  String _priorityLabel(String? p) {
    switch (p) {
      case 'HIGH':   return 'عالية';
      case 'MEDIUM': return 'متوسطة';
      case 'LOW':    return 'منخفضة';
      default:       return p ?? '--';
    }
  }

  void _showAdd() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
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
            Text('طلب صيانة جديد', style: AppText.h2, textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            _field(titleCtrl, 'عنوان الطلب'),
            const SizedBox(height: 10),
            _field(descCtrl, 'الوصف'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    await ApiService.post('/maintenance/', data: {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (_) {}
                },
                child: const Text('إرسال الطلب', style: TextStyle(fontFamily: 'Cairo')),
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
      bottomNavigationBar: const EngineerNav(selectedIndex: 1),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonCyan,
        onPressed: _showAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الصيانة'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد طلبات صيانة', icon: Icons.build_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final m = _items[i];
                            final priority = m['priority'] as String?;
                            final color = _priorityColor(priority);
                            return GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(m['title'] ?? '--', style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(_priorityLabel(priority),
                                            style: AppText.label.copyWith(color: color)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(m['description'] ?? m['machine']?['name'] ?? '--',
                                      style: AppText.caption,
                                      textDirection: TextDirection.rtl),
                                  const SizedBox(height: 4),
                                  Text(m['status'] ?? '--',
                                      style: AppText.label.copyWith(color: AppColors.neonCyan)),
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
