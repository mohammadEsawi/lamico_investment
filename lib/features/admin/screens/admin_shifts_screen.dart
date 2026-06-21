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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/shifts/');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['shifts'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _calcDuration(String? startIso, String? endIso) {
    if (startIso == null || endIso == null) return '--';
    final s = DateTime.tryParse(startIso);
    final e = DateTime.tryParse(endIso);
    if (s == null || e == null) return '--';
    var diff = e.difference(s);
    if (diff.isNegative) diff = diff + const Duration(hours: 24);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (m == 0) return '$h س';
    return '$h س $m د';
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) {
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
        textDirection: TextDirection.rtl,
        keyboardType: keyboardType,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body,
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _showShiftSheet({Map<String, dynamic>? shift}) {
    final nameCtrl = TextEditingController(text: shift?['name'] ?? '');
    DateTime? startDt = shift != null
        ? DateTime.tryParse(shift['startTime'] ?? '')
        : null;
    DateTime? endDt = shift != null
        ? DateTime.tryParse(shift['endTime'] ?? '')
        : null;

    final isEdit = shift != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'تعديل الوردية' : 'إضافة وردية جديدة',
                style: AppText.h2,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 20),
              _inputField(nameCtrl, 'اسم الوردية (مثال: A، B، C)'),
              const SizedBox(height: 12),
              _timePickerTile(
                label: 'وقت البداية',
                value: startDt,
                icon: Icons.access_time,
                color: AppColors.neonCyan,
                onPicked: (dt) => setLocal(() => startDt = dt),
              ),
              const SizedBox(height: 12),
              _timePickerTile(
                label: 'وقت النهاية',
                value: endDt,
                icon: Icons.access_time_filled,
                color: AppColors.neonPurple,
                onPicked: (dt) => setLocal(() => endDt = dt),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty || startDt == null || endDt == null) return;
                  try {
                    final payload = {
                      'name': name,
                      'startTime': startDt!.toIso8601String(),
                      'endTime': endDt!.toIso8601String(),
                    };
                    if (isEdit) {
                      await ApiService.put('/shifts/${shift['id']}',
                          data: payload);
                    } else {
                      await ApiService.post('/shifts/', data: payload);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (_) {}
                },
                child: Text(
                  isEdit ? 'حفظ التعديلات' : 'إضافة الوردية',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timePickerTile({
    required String label,
    required DateTime? value,
    required IconData icon,
    required Color color,
    required ValueChanged<DateTime> onPicked,
  }) {
    final display = value != null
        ? '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
        : 'اختر الوقت';

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value != null
              ? TimeOfDay(hour: value.hour, minute: value.minute)
              : TimeOfDay.now(),
          builder: (ctx, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
        if (picked != null) {
          final now = DateTime.now();
          onPicked(DateTime(
              now.year, now.month, now.day, picked.hour, picked.minute));
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label: $display',
                style: AppText.body.copyWith(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف الوردية',
            style: AppText.h2, textDirection: TextDirection.rtl),
        content: Text(
          'هل تريد حذف الوردية "${shift['name']}"؟ لا يمكن التراجع عن هذا الإجراء.',
          style: AppText.body,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء',
                style: AppText.body.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.delete('/shifts/${shift['id']}');
        _load();
      } catch (_) {}
    }
  }

  Widget _shiftCard(Map<String, dynamic> s) {
    final startTime = _formatTime(s['startTime'] as String?);
    final endTime = _formatTime(s['endTime'] as String?);
    final duration = _calcDuration(
        s['startTime'] as String?, s['endTime'] as String?);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule,
                    color: AppColors.neonPurple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s['name'] ?? '--',
                        style: AppText.h3,
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$startTime  ←  $endTime',
                          style: AppText.body.copyWith(
                              color: AppColors.neonCyan,
                              fontFamily: 'Cairo'),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_bottom,
                        color: AppColors.neonGold, size: 14),
                    const SizedBox(width: 4),
                    Text('المدة: $duration',
                        style: AppText.label
                            .copyWith(color: AppColors.neonGold)),
                  ],
                ),
              ),
              const Spacer(),
              _actionBtn(
                label: 'تعديل',
                icon: Icons.edit_outlined,
                color: AppColors.neonCyan,
                onTap: () => _showShiftSheet(shift: s),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                label: 'حذف',
                icon: Icons.delete_outline,
                color: AppColors.neonRed,
                onTap: () => _confirmDelete(s),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: AppText.label.copyWith(color: color),
                textDirection: TextDirection.rtl),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonPurple,
        onPressed: () => _showShiftSheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(
          children: [
            AiAppBar(
              title: 'إدارة الورديات',
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppColors.textSecondary),
                  onPressed: _load,
                ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const LoadingWidget()
                  : _items.isEmpty
                      ? const EmptyStateWidget(
                          message: 'لا توجد ورديات مسجلة',
                          icon: Icons.schedule_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _shiftCard(Map<String, dynamic>.from(_items[i])),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
