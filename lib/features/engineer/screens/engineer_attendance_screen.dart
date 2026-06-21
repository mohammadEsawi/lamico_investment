import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerAttendanceScreen extends StatefulWidget {
  const EngineerAttendanceScreen({super.key});
  @override
  State<EngineerAttendanceScreen> createState() => _EngineerAttendanceScreenState();
}

class _EngineerAttendanceScreenState extends State<EngineerAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _records = [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _selectedMonth;
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _timeFmt = DateFormat('HH:mm');

  final List<String> _months = List.generate(6, (i) {
    final d = DateTime.now().subtract(Duration(days: 30 * i));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  });

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _selectedMonth = _months.first;
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/attendance/me');
      final data = res.data;
      setState(() {
        _records = data is List ? data : (data['attendance'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _todayRecord {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final r in _records) {
      final raw = r['date'] ?? r['checkIn'] ?? r['createdAt'] ?? '';
      if (raw.toString().startsWith(today)) return r as Map<String, dynamic>;
    }
    return null;
  }

  List<dynamic> get _filteredRecords {
    if (_selectedMonth == null) return _records;
    return _records.where((r) {
      final raw = r['date'] ?? r['checkIn'] ?? r['createdAt'] ?? '';
      return raw.toString().startsWith(_selectedMonth!);
    }).toList();
  }

  Future<void> _checkIn() async {
    setState(() => _actionLoading = true);
    try {
      final res = await ApiService.post('/attendance/check-in', data: {});
      final data = res.data;
      final checkInTime = data['checkIn'] ?? data['attendance']?['checkIn'];
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('تم تسجيل الحضور', style: AppText.h3,
              textDirection: TextDirection.rtl),
          content: Text(
            'وقت الحضور: ${checkInTime != null ? _timeFmt.format(DateTime.parse(checkInTime.toString())) : '--'}',
            style: AppText.body.copyWith(color: AppColors.neonGreen),
            textDirection: TextDirection.rtl,
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.neonRed),
      );
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _actionLoading = true);
    try {
      final res = await ApiService.post('/attendance/check-out', data: {});
      final data = res.data;
      final record = data['attendance'] ?? data;
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('تم تسجيل الانصراف', style: AppText.h3,
              textDirection: TextDirection.rtl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('وقت الانصراف: ${record['checkOut'] != null ? _timeFmt.format(DateTime.parse(record['checkOut'].toString())) : '--'}',
                  style: AppText.body, textDirection: TextDirection.rtl),
              if ((record['overtimeMinutes'] ?? 0) > 0)
                Text('وقت إضافي: ${record['overtimeMinutes']} دقيقة',
                    style: AppText.body.copyWith(color: AppColors.neonGold),
                    textDirection: TextDirection.rtl),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: AppColors.neonRed),
      );
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'PRESENT':  return AppColors.neonGreen;
      case 'LATE':     return AppColors.neonOrange;
      case 'ABSENT':   return AppColors.neonRed;
      case 'HALF_DAY': return AppColors.neonGold;
      default:         return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'PRESENT':  return 'حاضر';
      case 'LATE':     return 'متأخر';
      case 'ABSENT':   return 'غائب';
      case 'HALF_DAY': return 'نصف يوم';
      default:         return s ?? '--';
    }
  }

  String _fmt(String? iso) {
    if (iso == null) return '--';
    try { return _timeFmt.format(DateTime.parse(iso)); } catch (_) { return '--'; }
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '--';
    try { return _dateFmt.format(DateTime.parse(raw.toString())); } catch (_) { return '--'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 4),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الحضور والانصراف'),
          TabBar(controller: _tabs, tabs: const [Tab(text: 'اليوم'), Tab(text: 'السجل')]),
          Expanded(
            child: TabBarView(controller: _tabs, children: [_buildToday(), _buildHistory()]),
          ),
        ]),
      ),
    );
  }

  Widget _buildToday() {
    final today = _todayRecord;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GlassCard(
            child: Column(children: [
              Text(DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: AppText.h3, textDirection: TextDirection.rtl),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _actionBtn('تسجيل الحضور', Icons.login, AppColors.neonGreen, _checkIn),
                _actionBtn('تسجيل الانصراف', Icons.logout, AppColors.neonOrange, _checkOut),
              ]),
              if (_actionLoading) ...[const SizedBox(height: 16), const CircularProgressIndicator()],
            ]),
          ),
          const SizedBox(height: 16),
          if (today != null)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سجل اليوم', style: AppText.h3, textDirection: TextDirection.rtl),
                  const SizedBox(height: 12),
                  _infoRow('الوردية', today['shift']?['name'] ?? '--'),
                  _infoRow('تسجيل الحضور', _fmt(today['checkIn']?.toString())),
                  _infoRow('تسجيل الانصراف', _fmt(today['checkOut']?.toString())),
                  _infoRow('الحالة', _statusLabel(today['status'] as String?),
                      color: _statusColor(today['status'] as String?)),
                  if ((today['lateMinutes'] ?? 0) > 0)
                    _infoRow('دقائق التأخير', '${today['lateMinutes']} دقيقة',
                        color: AppColors.neonOrange),
                  if ((today['overtimeMinutes'] ?? 0) > 0)
                    _infoRow('وقت إضافي', '${today['overtimeMinutes']} دقيقة',
                        color: AppColors.neonGold),
                ],
              ),
            )
          else
            GlassCard(
              child: Text('لا يوجد تسجيل حضور لهذا اليوم',
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                  textDirection: TextDirection.rtl),
            ),
        ]),
      ),
    );
  }

  Widget _buildHistory() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: DropdownButtonFormField<String>(
            value: _selectedMonth,
            decoration: InputDecoration(
              labelText: 'الشهر',
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            items: _months
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _selectedMonth = v),
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? const LoadingWidget()
            : _filteredRecords.isEmpty
                ? const Center(child: Text('لا يوجد سجلات', textDirection: TextDirection.rtl))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredRecords.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = _filteredRecords[i];
                        final status = r['status'] as String?;
                        final color = _statusColor(status);
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmtDate(r['date'] ?? r['checkIn'] ?? r['createdAt']),
                                        style: AppText.h3,
                                        textDirection: TextDirection.rtl),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${r['shift']?['name'] ?? '--'}  •  دخول: ${_fmt(r['checkIn']?.toString())}  •  خروج: ${_fmt(r['checkOut']?.toString())}',
                                      style: AppText.caption,
                                      textDirection: TextDirection.rtl,
                                    ),
                                    if ((r['overtimeMinutes'] ?? 0) > 0)
                                      Text('وقت إضافي: ${r['overtimeMinutes']} دقيقة',
                                          style: AppText.caption
                                              .copyWith(color: AppColors.neonGold),
                                          textDirection: TextDirection.rtl),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    ]);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: _actionLoading ? null : onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _infoRow(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.caption, textDirection: TextDirection.rtl),
            Text(value,
                style: AppText.body.copyWith(color: color ?? AppColors.textPrimary),
                textDirection: TextDirection.rtl),
          ],
        ),
      );
}
