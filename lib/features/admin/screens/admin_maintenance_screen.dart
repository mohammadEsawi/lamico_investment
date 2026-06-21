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

class AdminMaintenanceScreen extends StatefulWidget {
  const AdminMaintenanceScreen({super.key});
  @override
  State<AdminMaintenanceScreen> createState() => _AdminMaintenanceScreenState();
}

class _AdminMaintenanceScreenState extends State<AdminMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<dynamic> _records = [];
  List<dynamic> _machines = [];
  bool _loadingRecords = true;
  String? _filterStatus;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  // Add form controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  dynamic _addMachineId;
  String _addPriority = 'MEDIUM';
  DateTime? _addScheduledDate;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadRecords();
    _loadMachines();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _loadingRecords = true);
    try {
      final res = await ApiService.get('/maintenance');
      final data = res.data;
      setState(() {
        _records = data is List ? data : (data['maintenance'] ?? data['data'] ?? []);
        _loadingRecords = false;
      });
    } catch (_) {
      setState(() => _loadingRecords = false);
    }
  }

  Future<void> _loadMachines() async {
    try {
      final res = await ApiService.get('/machines/');
      final data = res.data;
      setState(() {
        _machines = data is List ? data : (data['machines'] ?? data['data'] ?? []);
      });
    } catch (_) {}
  }

  List<dynamic> get _filteredRecords {
    if (_filterStatus == null) return _records;
    return _records.where((r) => r['status'] == _filterStatus).toList();
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'PENDING': return 'معلق';
      case 'IN_PROGRESS': return 'جارٍ';
      case 'COMPLETED': return 'مكتمل';
      case 'CANCELLED': return 'ملغى';
      default: return s ?? '--';
    }
  }

  String _priorityLabel(String? p) {
    switch (p) {
      case 'LOW': return 'منخفض';
      case 'MEDIUM': return 'متوسط';
      case 'HIGH': return 'عالٍ';
      case 'CRITICAL': return 'حرج';
      default: return p ?? '--';
    }
  }

  Color _priorityColor(String? p) {
    switch (p) {
      case 'CRITICAL': return AppColors.neonRed;
      case 'HIGH': return AppColors.neonOrange;
      case 'MEDIUM': return AppColors.neonGold;
      case 'LOW': return AppColors.neonCyan;
      default: return AppColors.textSecondary;
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'PENDING': return AppColors.neonGold;
      case 'IN_PROGRESS': return AppColors.neonCyan;
      case 'COMPLETED': return AppColors.neonGreen;
      case 'CANCELLED': return AppColors.neonRed;
      default: return AppColors.textSecondary;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '--';
    try {
      return _dateFmt.format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  void _showEditSheet(Map<String, dynamic> record) {
    String selStatus = record['status'] ?? 'PENDING';
    final assignedCtrl = TextEditingController(
        text: record['assignedToId']?.toString() ?? '');
    final costCtrl = TextEditingController(
        text: record['cost'] != null ? '${record['cost']}' : '');
    final notesCtrl = TextEditingController(text: record['notes'] ?? '');

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
                  Text('تعديل طلب الصيانة', style: AppText.h2),
                  const SizedBox(height: 16),
                  _label('الحالة'),
                  const SizedBox(height: 6),
                  _enumDropdown(
                    value: selStatus,
                    items: const ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'],
                    labelFn: _statusLabel,
                    onChanged: (v) => setS(() => selStatus = v!),
                  ),
                  const SizedBox(height: 12),
                  _label('معرّف المسؤول (اختياري)'),
                  const SizedBox(height: 6),
                  _field(assignedCtrl, 'معرّف المستخدم المسؤول'),
                  const SizedBox(height: 12),
                  _label('التكلفة (اختياري)'),
                  const SizedBox(height: 6),
                  _field(costCtrl, 'التكلفة بالأرقام',
                      keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  _label('ملاحظات'),
                  const SizedBox(height: 6),
                  _field(notesCtrl, 'ملاحظات إضافية', maxLines: 3),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final payload = <String, dynamic>{
                        'status': selStatus,
                      };
                      final assigned = assignedCtrl.text.trim();
                      if (assigned.isNotEmpty) payload['assignedToId'] = assigned;
                      final costVal = costCtrl.text.trim();
                      if (costVal.isNotEmpty) {
                        payload['cost'] = double.tryParse(costVal) ?? 0.0;
                      }
                      final notesVal = notesCtrl.text.trim();
                      if (notesVal.isNotEmpty) payload['notes'] = notesVal;
                      try {
                        await ApiService.patch(
                            '/maintenance/${record['id']}', data: payload);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadRecords();
                      } catch (_) {}
                    },
                    child: const Text(
                      'حفظ التغييرات',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
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

  void _showAddDialog() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _notesCtrl.clear();
    _addMachineId = null;
    _addPriority = 'MEDIUM';
    _addScheduledDate = null;

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
                  Text('إضافة طلب صيانة', style: AppText.h2),
                  const SizedBox(height: 16),
                  _label('العنوان'),
                  const SizedBox(height: 6),
                  _field(_titleCtrl, 'عنوان الطلب'),
                  const SizedBox(height: 12),
                  _label('الوصف'),
                  const SizedBox(height: 6),
                  _field(_descCtrl, 'وصف المشكلة', maxLines: 3),
                  const SizedBox(height: 12),
                  _label('الآلة'),
                  const SizedBox(height: 6),
                  _machineDropdown(
                    value: _addMachineId,
                    onChanged: (v) => setS(() => _addMachineId = v),
                  ),
                  const SizedBox(height: 12),
                  _label('الأولوية'),
                  const SizedBox(height: 6),
                  _enumDropdown(
                    value: _addPriority,
                    items: const ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
                    labelFn: _priorityLabel,
                    onChanged: (v) => setS(() => _addPriority = v!),
                  ),
                  const SizedBox(height: 12),
                  _label('التاريخ المجدول (اختياري)'),
                  const SizedBox(height: 6),
                  _dateButton(
                    value: _addScheduledDate,
                    hint: 'اختر تاريخاً',
                    onPick: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setS(() => _addScheduledDate = d);
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('ملاحظات (اختياري)'),
                  const SizedBox(height: 6),
                  _field(_notesCtrl, 'ملاحظات', maxLines: 2),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (_titleCtrl.text.trim().isEmpty ||
                          _addMachineId == null) return;
                      final payload = <String, dynamic>{
                        'title': _titleCtrl.text.trim(),
                        'description': _descCtrl.text.trim(),
                        'machineId': _addMachineId,
                        'priority': _addPriority,
                      };
                      if (_addScheduledDate != null) {
                        payload['scheduledDate'] =
                            _addScheduledDate!.toUtc().toIso8601String();
                      }
                      final notes = _notesCtrl.text.trim();
                      if (notes.isNotEmpty) payload['notes'] = notes;
                      try {
                        await ApiService.post('/maintenance', data: payload);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadRecords();
                      } catch (_) {}
                    },
                    child: const Text(
                      'إضافة الطلب',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
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

  void _confirmDelete(dynamic id) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('حذف الطلب', style: AppText.h3),
          content: Text('هل أنت متأكد من حذف طلب الصيانة هذا؟', style: AppText.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.delete('/maintenance/$id');
                  _loadRecords();
                } catch (_) {}
              },
              child: Text('حذف',
                  style: AppText.body.copyWith(color: AppColors.neonRed)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable helpers ─────────────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) =>
      Container(
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
          maxLines: maxLines,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body,
            border: InputBorder.none,
          ),
        ),
      );

  Widget _enumDropdown({
    required String value,
    required List<String> items,
    required String Function(String) labelFn,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.bgCard,
            style: AppText.body.copyWith(color: AppColors.textPrimary),
            items: items
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(labelFn(e),
                          style: AppText.body
                              .copyWith(color: AppColors.textPrimary),
                          textDirection: TextDirection.rtl),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _machineDropdown({
    required dynamic value,
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
            hint:
                Text('اختر الآلة', style: AppText.body),
            isExpanded: true,
            dropdownColor: AppColors.bgCard,
            style: AppText.body.copyWith(color: AppColors.textPrimary),
            items: _machines
                .map((m) => DropdownMenuItem<dynamic>(
                      value: m['id'],
                      child: Text(m['name'] ?? '--',
                          style: AppText.body
                              .copyWith(color: AppColors.textPrimary),
                          textDirection: TextDirection.rtl),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _dateButton({
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
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.textSecondary, size: 18),
              Text(
                value != null ? _dateFmt.format(value) : hint,
                style: AppText.body.copyWith(
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
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
        child: Text(label,
            style: AppText.caption.copyWith(color: color, fontSize: 11)),
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 4),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonOrange,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(
          children: [
            const AiAppBar(title: 'الصيانة'),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildRequestsTab(),
                  _buildScheduleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              color: AppColors.neonOrange.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: AppText.label.copyWith(color: AppColors.textPrimary),
            unselectedLabelStyle:
                AppText.label.copyWith(color: AppColors.textSecondary),
            tabs: const [
              Tab(text: 'طلبات الصيانة'),
              Tab(text: 'جدول الصيانة'),
            ],
          ),
        ),
      );

  Widget _buildRequestsTab() {
    return Column(
      children: [
        _buildStatusFilter(),
        Expanded(
          child: _loadingRecords
              ? const LoadingWidget()
              : _buildRecordsList(_filteredRecords),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Text('الحالة:', style: AppText.label.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _filterStatus,
                    hint: Text('الكل', style: AppText.body),
                    isExpanded: true,
                    dropdownColor: AppColors.bgCard,
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('الكل',
                            style: AppText.body
                                .copyWith(color: AppColors.textPrimary)),
                      ),
                      ...['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']
                          .map((s) => DropdownMenuItem<String?>(
                                value: s,
                                child: Text(_statusLabel(s),
                                    style: AppText.body.copyWith(
                                        color: AppColors.textPrimary)),
                              )),
                    ],
                    onChanged: (v) => setState(() => _filterStatus = v),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildRecordsList(List<dynamic> list) {
    if (list.isEmpty) {
      return const EmptyStateWidget(
        message: 'لا توجد طلبات صيانة',
        icon: Icons.build_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = list[i];
          final machine = r['machine'];
          final machineName =
              (machine is Map ? machine['name'] : null) ?? '--';
          final requestedBy = r['requestedBy'];
          final requesterName =
              (requestedBy is Map ? requestedBy['fullName'] : null) ?? '--';
          final assignedTo = r['assignedTo'];
          final assigneeName =
              (assignedTo is Map ? assignedTo['fullName'] : null);
          final priority = r['priority'] as String?;
          final status = r['status'] as String?;
          final scheduledDate = r['scheduledDate'] as String?;
          final cost = r['cost'];

          return GestureDetector(
            onTap: () => _showEditSheet(Map<String, dynamic>.from(r)),
            onLongPress: () => _confirmDelete(r['id']),
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
                          color: _priorityColor(priority)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.build_circle_outlined,
                            color: _priorityColor(priority), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(r['title'] ?? '--',
                                style: AppText.h3,
                                textDirection: TextDirection.rtl),
                            Text(machineName,
                                style: AppText.caption.copyWith(
                                    color: AppColors.textSecondary),
                                textDirection: TextDirection.rtl),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _badge(_priorityLabel(priority), _priorityColor(priority)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),
                  Wrap(
                    textDirection: TextDirection.rtl,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _badge(_statusLabel(status), _statusColor(status)),
                      _badge('بواسطة: $requesterName', AppColors.textSecondary),
                      if (assigneeName != null)
                        _badge('مسؤول: $assigneeName', AppColors.neonPurple),
                      if (scheduledDate != null)
                        _badge(
                            'مجدول: ${_formatDate(scheduledDate)}',
                            AppColors.neonCyan),
                      if (cost != null)
                        _badge('التكلفة: $cost ر.س', AppColors.neonGold),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (_loadingRecords) return const LoadingWidget();

    final statusOrder = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
    final counts = <String, int>{};
    for (final s in statusOrder) {
      counts[s] = _records.where((r) => r['status'] == s).length;
    }

    final sorted = List<dynamic>.from(_records)..sort((a, b) {
        final da = a['scheduledDate'] as String?;
        final db = b['scheduledDate'] as String?;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Status summary chips
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusOrder
                  .map((s) => GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${counts[s] ?? 0}',
                              style: AppText.h3
                                  .copyWith(color: _statusColor(s)),
                            ),
                            const SizedBox(width: 6),
                            Text(_statusLabel(s), style: AppText.body),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text('مرتبة حسب التاريخ المجدول',
              style: AppText.label.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            const EmptyStateWidget(
              message: 'لا توجد طلبات صيانة',
              icon: Icons.calendar_month_outlined,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = sorted[i];
                final machine = r['machine'];
                final machineName =
                    (machine is Map ? machine['name'] : null) ?? '--';
                final scheduledDate = r['scheduledDate'] as String?;
                final priority = r['priority'] as String?;
                final status = r['status'] as String?;

                return GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _statusColor(status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(r['title'] ?? '--',
                                style: AppText.h3,
                                textDirection: TextDirection.rtl),
                            Text(machineName,
                                style: AppText.caption.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _badge(_priorityLabel(priority),
                              _priorityColor(priority)),
                          const SizedBox(height: 4),
                          Text(
                            scheduledDate != null
                                ? _formatDate(scheduledDate)
                                : 'غير محدد',
                            style: AppText.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
