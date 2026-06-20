import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/worker_nav.dart';

class WorkerAttendanceScreen extends StatefulWidget {
  const WorkerAttendanceScreen({super.key});
  @override
  State<WorkerAttendanceScreen> createState() => _WorkerAttendanceScreenState();
}

class _WorkerAttendanceScreenState extends State<WorkerAttendanceScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _checkingIn  = false;
  bool _checkingOut = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/attendance/me');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['records'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    try {
      await ApiService.post('/attendance/check-in');
      _load();
    } catch (_) {} finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _checkingOut = true);
    try {
      await ApiService.post('/attendance/check-out');
      _load();
    } catch (_) {} finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'PRESENT': return AppColors.neonGreen;
      case 'ABSENT':  return AppColors.neonRed;
      case 'LATE':    return AppColors.neonGold;
      default:        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'PRESENT': return 'حاضر';
      case 'ABSENT':  return 'غائب';
      case 'LATE':    return 'متأخر';
      default:        return s ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const WorkerNav(selectedIndex: 2),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الحضور'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _checkingIn ? null : _checkIn,
                      icon: _checkingIn
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.login, size: 18),
                      label: const Text('تسجيل دخول', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonRed,
                        side: const BorderSide(color: AppColors.neonRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _checkingOut ? null : _checkOut,
                      icon: _checkingOut
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(color: AppColors.neonRed, strokeWidth: 2))
                          : const Icon(Icons.logout, size: 18),
                      label: const Text('تسجيل خروج', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد سجلات حضور', icon: Icons.fingerprint)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                                        Text(a['date']?.toString().substring(0, 10) ?? '--',
                                            style: AppText.h3, textDirection: TextDirection.rtl),
                                        Text('دخول: ${a['checkIn'] ?? '--'}  |  خروج: ${a['checkOut'] ?? '--'}',
                                            style: AppText.caption, textDirection: TextDirection.rtl),
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
