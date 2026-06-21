import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
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

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _records = [];
  List<dynamic> _users = [];
  List<dynamic> _shifts = [];
  bool _loadingRecords = true;
  bool _loadingSettings = true;
  DateTime? _filterDate = DateTime.now();
  final _lateCtrl = TextEditingController();
  final _overtimeCtrl = TextEditingController();
  final _fmt = DateFormat('dd/MM/yyyy HH:mm');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadRecords();
    _loadSettings();
    _loadUsers();
    _loadShifts();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _lateCtrl.dispose();
    _overtimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _loadingRecords = true);
    try {
      final res = await ApiService.get('/attendance/all');
      final data = res.data;
      setState(() {
        _records = data is List ? data : (data['attendance'] ?? data['data'] ?? []);
        _loadingRecords = false;
      });
    } catch (_) {
      setState(() => _loadingRecords = false);
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _loadingSettings = true);
    try {
      final res = await ApiService.get('/attendance/settings');
      final d = res.data is Map ? res.data as Map : {};
      setState(() {
        _lateCtrl.text = '${d['lateGraceMinutes'] ?? ''}';
        _overtimeCtrl.text = '${d['overtimeGraceMinutes'] ?? ''}';
        _loadingSettings = false;
      });
    } catch (_) {
      setState(() => _loadingSettings = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final res = await ApiService.get('/users/all');
      final data = res.data;
      setState(() {
        _users = data is List ? data : (data['users'] ?? data['data'] ?? []);
      });
    } catch (_) {}
  }

  Future<void> _loadShifts() async {
    try {
      final res = await ApiService.get('/shifts/');
      final data = res.data;
      setState(() {
        _shifts = data is List ? data : (data['shifts'] ?? data['data'] ?? []);
      });
    } catch (_) {}
  }

  List<dynamic> get _filteredRecords {
    if (_filterDate == null) return _records;
    return _records.where((r) {
      final ci = r['checkIn'] as String?;
      if (ci == null) return false;
      try {
        final d = DateTime.parse(ci).toLocal();
        return d.year == _filterDate!.year &&
            d.month == _filterDate!.month &&
            d.day == _filterDate!.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _filterDate = picked);
  }

  String _formatDt(String? iso) {
    if (iso == null) return '--';
    try {
      return _fmt.format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  dynamic _safeNested(dynamic map, String key) {
    if (map == null) return null;
    if (map is Map) return map[key];
    return null;
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final userMap = existing != null ? _safeNested(existing['user'], 'id') : null;
    final shiftMap = existing != null ? _safeNested(existing['shift'], 'id') : null;
    dynamic selectedUser = existing != null ? (existing['userId'] ?? userMap) : null;
    dynamic selectedShift = existing != null ? (existing['shiftId'] ?? shiftMap) : null;
    final checkInStr = existing != null ? existing['checkIn'] as String? : null;
    final checkOutStr = existing != null ? existing['checkOut'] as String? : null;
    DateTime? checkIn = checkInStr != null ? DateTime.tryParse(checkInStr)?.toLocal() : null;
    DateTime? checkOut = checkOutStr != null ? DateTime.tryParse(checkOutStr)?.toLocal() : null;
    final notesCtrl = TextEditingController(text: existing != null ? (existing['notes'] ?? '') : '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              right: 24,
              left: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(existing == null ? 'إضافة سجل حضور' : 'تعديل سجل الحضور',
                      style: AppText.h2),
                  const SizedBox(height: 16),
                  _label('الموظف'),
                  const SizedBox(height: 6),
                  _dropdown(
                    value: selectedUser,
                    items: _users,
                    nameKey: 'name',
                    idKey: 'id',
                    hint: 'اختر الموظف',
                    onChanged: (v) => setS(() => selectedUser = v),
                  ),
                  const SizedBox(height: 12),
                  _label('الوردية'),
                  const SizedBox(height: 6),
                  _dropdown(
                    value: selectedShift,
                    items: _shifts,
                    nameKey: 'name',
                    idKey: 'id',
                    hint: 'اختر الوردية',
                    onChanged: (v) => setS(() => selectedShift = v),
                  ),
                  const SizedBox(height: 12),
                  _label('وقت الدخول'),
                  const SizedBox(height: 6),
                  _dtButton(
                    value: checkIn,
                    hint: 'اختر وقت الدخول',
                    onPick: () async {
                      final d = await _pickDateTime(ctx, checkIn);
                      if (d != null) setS(() => checkIn = d);
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('وقت الخروج (اختياري)'),
                  const SizedBox(height: 6),
                  _dtButton(
                    value: checkOut,
                    hint: 'اختر وقت الخروج',
                    onPick: () async {
                      final d = await _pickDateTime(ctx, checkOut);
                      if (d != null) setS(() => checkOut = d);
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('ملاحظات'),
                  const SizedBox(height: 6),
                  _field(notesCtrl, 'ملاحظات اختيارية'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (selectedUser == null || selectedShift == null || checkIn == null) return;
                      final payload = <String, dynamic>{
                        'userId': selectedUser,
                        'shiftId': selectedShift,
                        'checkIn': checkIn!.toUtc().toIso8601String(),
                      };
                      if (checkOut != null) payload['checkOut'] = checkOut!.toUtc().toIso8601String();
                      final notes = notesCtrl.text.trim();
                      if (notes.isNotEmpty) payload['notes'] = notes;
                      try {
                        if (existing == null) {
                          await ApiService.post('/attendance/', data: payload);
                        } else {
                          await ApiService.put('/attendance/${existing['id']}', data: payload);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadRecords();
                      } catch (_) {}
                    },
                    child: Text(
                      existing == null ? 'إضافة' : 'حفظ التغييرات',
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext ctx, DateTime? initial) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !ctx.mounted) return null;
    final time = await showTimePicker(
      context: ctx,
      initialTime: initial != null ? TimeOfDay.fromDateTime(initial) : TimeOfDay.now(),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _confirmDelete(dynamic id) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('حذف السجل', style: AppText.h3),
          content: Text('هل أنت متأكد من حذف هذا السجل؟', style: AppText.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.delete('/attendance/$id');
                  _loadRecords();
                } catch (_) {}
              },
              child: Text('حذف', style: AppText.body.copyWith(color: AppColors.neonRed)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {TextInputType? keyboard}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: TextField(
          controller: ctrl,
          textAlign: TextAlign.right,
          keyboardType: keyboard,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body,
            border: InputBorder.none,
          ),
        ),
      );

  Widget _dropdown({
    required dynamic value,
    required List<dynamic> items,
    required String nameKey,
    required String idKey,
    required String hint,
    required ValueChanged<dynamic> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<dynamic>(
            value: value,
            hint: Text(hint, style: AppText.body),
            isExpanded: true,
            dropdownColor: AppColors.bgCard,
            style: AppText.body.copyWith(color: AppColors.textPrimary),
            items: items.map((item) {
              return DropdownMenuItem<dynamic>(
                value: item[idKey],
                child: Text(
                  item[nameKey] ?? '--',
                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                  textDirection: TextDirection.rtl,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _dtButton({
    required DateTime? value,
    required String hint,
    required VoidCallback onPick,
  }) =>
      GestureDetector(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 18),
              Text(
                value != null ? _fmt.format(value) : hint,
                style: AppText.body.copyWith(
                  color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _label(String text) =>
      Text(text, style: AppText.label.copyWith(color: AppColors.textSecondary));

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: AppText.caption.copyWith(color: color, fontSize: 11)),
      );

  Widget _timeChip(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: AppText.caption.copyWith(color: color)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonPurple,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(
          children: [
            AiAppBar(title: 'الحضور'),
            _buildFilterBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildRecordsTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickFilterDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.neonCyan, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _filterDate != null
                            ? _dateFmt.format(_filterDate!)
                            : 'اختر تاريخاً',
                        style: AppText.body.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _filterDate = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _filterDate == null
                      ? AppColors.neonPurple.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _filterDate == null
                        ? AppColors.neonPurple
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'كل السجلات',
                  style: AppText.caption.copyWith(
                    color: _filterDate == null
                        ? AppColors.neonPurple
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: AppText.label.copyWith(color: AppColors.textPrimary),
            unselectedLabelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
            tabs: const [
              Tab(text: 'سجلات الحضور'),
              Tab(text: 'إعدادات الحضور'),
            ],
          ),
        ),
      );

  Widget _buildRecordsTab() {
    if (_loadingRecords) return const LoadingWidget();
    final visible = _filteredRecords;
    if (visible.isEmpty) {
      return const EmptyStateWidget(
        message: 'لا توجد سجلات للتاريخ المحدد',
        icon: Icons.fingerprint,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final a = visible[i];
          final user = a['user'];
          final shift = a['shift'];
          final userName =
              (user is Map ? user['name'] : null) ?? a['userName'] ?? '--';
          final userRole = (user is Map ? user['role'] : null) ?? a['role'] ?? '';
          final shiftName =
              (shift is Map ? shift['name'] : null) ?? a['shiftName'] ?? '--';
          final checkIn = a['checkIn'] as String?;
          final checkOut = a['checkOut'] as String?;
          final lateMin = (a['lateMinutes'] ?? 0);
          final overtimeMin = (a['overtimeMinutes'] ?? 0);
          final notes = a['notes'] as String?;
          final lateVal = lateMin is int ? lateMin : int.tryParse('$lateMin') ?? 0;
          final otVal = overtimeMin is int ? overtimeMin : int.tryParse('$overtimeMin') ?? 0;

          return GestureDetector(
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.bgCard,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined, color: AppColors.neonCyan),
                        title: Text('تعديل',
                            style: AppText.body.copyWith(color: AppColors.textPrimary)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showForm(existing: Map<String, dynamic>.from(a));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: AppColors.neonRed),
                        title: Text('حذف',
                            style: AppText.body.copyWith(color: AppColors.neonRed)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmDelete(a['id']);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fingerprint,
                            color: AppColors.neonPurple, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(userName,
                                style: AppText.h3,
                                textDirection: TextDirection.rtl),
                            if ((userRole as String).isNotEmpty)
                              Text(userRole,
                                  style: AppText.caption
                                      .copyWith(color: AppColors.textSecondary),
                                  textDirection: TextDirection.rtl),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(shiftName,
                            style: AppText.caption
                                .copyWith(color: AppColors.neonBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      _timeChip(Icons.login_outlined, _formatDt(checkIn),
                          AppColors.neonGreen),
                      const SizedBox(width: 10),
                      _timeChip(
                        Icons.logout_outlined,
                        checkOut != null ? _formatDt(checkOut) : 'لم يغادر',
                        checkOut != null
                            ? AppColors.neonOrange
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                  if (lateVal > 0 || otVal > 0 || (notes != null && notes.isNotEmpty)) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (lateVal > 0) _badge('تأخير $lateVal د', AppColors.neonOrange),
                        if (otVal > 0) _badge('إضافي $otVal د', AppColors.neonGreen),
                        if (notes != null && notes.isNotEmpty)
                          _badge(notes, AppColors.textSecondary),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_loadingSettings) return const LoadingWidget();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إعدادات الحضور', style: AppText.h2),
              const SizedBox(height: 18),
              _label('دقائق التسامح للتأخير'),
              const SizedBox(height: 6),
              _field(_lateCtrl, 'مثال: 10', keyboard: TextInputType.number),
              const SizedBox(height: 14),
              _label('دقائق التسامح للإضافي'),
              const SizedBox(height: 6),
              _field(_overtimeCtrl, 'مثال: 15', keyboard: TextInputType.number),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'التأخير يُحتسب بعد ${_lateCtrl.text.isEmpty ? '؟' : _lateCtrl.text} دقيقة من بدء الوردية',
                  style: AppText.caption.copyWith(color: AppColors.neonCyan),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  try {
                    await ApiService.put('/attendance/settings', data: {
                      'lateGraceMinutes':
                          int.tryParse(_lateCtrl.text.trim()) ?? 0,
                      'overtimeGraceMinutes':
                          int.tryParse(_overtimeCtrl.text.trim()) ?? 0,
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ الإعدادات')),
                      );
                    }
                    _loadSettings();
                  } catch (_) {}
                },
                child: const Text(
                  'حفظ الإعدادات',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
