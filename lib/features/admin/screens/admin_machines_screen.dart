import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminMachinesScreen extends StatefulWidget {
  const AdminMachinesScreen({super.key});

  @override
  State<AdminMachinesScreen> createState() => _AdminMachinesScreenState();
}

class _AdminMachinesScreenState extends State<AdminMachinesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/machines/');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['machines'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'OPERATIONAL':       return AppColors.neonGreen;
      case 'UNDER_MAINTENANCE': return AppColors.neonGold;
      case 'BROKEN':            return AppColors.neonRed;
      default:                  return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'OPERATIONAL':       return 'تشغيلية';
      case 'UNDER_MAINTENANCE': return 'تحت الصيانة';
      case 'BROKEN':            return 'معطلة';
      default:                  return status ?? '--';
    }
  }

  void _showAddMachine() {
    final nameCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إضافة آلة جديدة', style: AppText.h2,
                textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            _inputField(nameCtrl, 'اسم الآلة'),
            const SizedBox(height: 12),
            _inputField(modelCtrl, 'الموديل'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    await ApiService.post('/machines/', data: {
                      'name': nameCtrl.text.trim(),
                      'model': modelCtrl.text.trim(),
                    });
                    if (!mounted) return;
                    Navigator.pop(context);
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

  Widget _inputField(TextEditingController ctrl, String hint) {
    return Container(
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
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body,
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 3),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonPurple,
        onPressed: _showAddMachine,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الآلات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(
                        message: 'لا توجد آلات مسجلة',
                        icon: Icons.precision_manufacturing_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final m = _items[i];
                            final status = m['status'] as String?;
                            final color = _statusColor(status);
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.precision_manufacturing,
                                        color: color, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m['name'] ?? '--',
                                            style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text(m['model'] ?? '--',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(_statusLabel(status),
                                              style: AppText.label.copyWith(color: color)),
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
