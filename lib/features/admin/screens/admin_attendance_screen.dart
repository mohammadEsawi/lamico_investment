import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/attendance/all');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['attendance'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'PRESENT': return AppColors.neonGreen;
      case 'ABSENT':  return AppColors.neonRed;
      case 'LATE':    return AppColors.neonGold;
      default:        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'PRESENT': return 'حاضر';
      case 'ABSENT':  return 'غائب';
      case 'LATE':    return 'متأخر';
      default:        return status ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الحضور'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد سجلات حضور', icon: Icons.fingerprint)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _x) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final a = _items[i];
                            final status = a['status'] as String?;
                            final color = _statusColor(status);
                            return GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    width: 4, height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a['user']?['name'] ?? a['userName'] ?? '--',
                                            style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text(a['date'] ?? '--',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(_statusLabel(status),
                                        style: AppText.label.copyWith(color: color)),
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
