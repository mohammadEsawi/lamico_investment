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

class EngineerMaintenanceScheduleScreen extends StatefulWidget {
  const EngineerMaintenanceScheduleScreen({super.key});
  @override
  State<EngineerMaintenanceScheduleScreen> createState() =>
      _EngineerMaintenanceScheduleScreenState();
}

class _EngineerMaintenanceScheduleScreenState
    extends State<EngineerMaintenanceScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _schedules = [];
  List<dynamic> _machines = [];
  bool _loading = true;

  // form
  String? _fMachineId;
  final _fTitle = TextEditingController();
  final _fDesc = TextEditingController();
  String _fType = 'WEEKLY';
  DateTime? _fNextDue;
  final _fDuration = TextEditingController();
  final _fNotes = TextEditingController();
  bool _submitting = false;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  static const _types = ['DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUAL'];
  static const _typeLabels = {
    'DAILY': 'يومي', 'WEEKLY': 'أسبوعي', 'MONTHLY': 'شهري',
    'QUARTERLY': 'ربع سنوي', 'ANNUAL': 'سنوي',
  };
  static const _typeColors = {
    'DAILY': AppColors.neonCyan, 'WEEKLY': AppColors.neonGreen,
    'MONTHLY': AppColors.neonGold, 'QUARTERLY': AppColors.neonOrange,
    'ANNUAL': AppColors.neonPurple,
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _fTitle.dispose();
    _fDesc.dispose();
    _fDuration.dispose();
    _fNotes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/maintenance-schedules'),
        ApiService.get('/machines/'),
      ]);
      final d0 = results[0].data;
      final d1 = results[1].data;
      setState(() {
        _schedules = d0 is List ? d0 : (d0['schedules'] ?? d0['data'] ?? []);
        _machines = d1 is List ? d1 : (d1['machines'] ?? d1['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _toggleActive(Map<String, dynamic> s) async {
    try {
      await ApiService.patch('/maintenance-schedules/${s['id']}',
          data: {'isActive': !(s['isActive'] ?? true)});
      _load();
    } catch (_) {}
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('تأكيد الحذف', style: AppText.h3,
            textDirection: TextDirection.rtl),
        content: const Text('هل تريد حذف هذا الجدول؟',
            style: AppText.body, textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.delete('/maintenance-schedules/$id');
        _load();
      } catch (_) {}
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fNextDue ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d != null) setState(() => _fNextDue = d);
  }

  Future<void> _submit() async {
    if (_fTitle.text.isEmpty || _fMachineId == null || _fNextDue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة الحقول المطلوبة'),
            backgroundColor: AppColors.neonRed),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.post('/maintenance-schedules', data: {
        'machineId': _fMachineId,
        'title': _fTitle.text,
        if (_fDesc.text.isNotEmpty) 'description': _fDesc.text,
        'scheduleType': _fType,
        'nextDueDate': _fNextDue!.toIso8601String(),
        if (_fDuration.text.isNotEmpty)
          'estimatedDuration': int.tryParse(_fDuration.text),
        if (_fNotes.text.isNotEmpty) 'notes': _fNotes.text,
      });
      _fTitle.clear(); _fDesc.clear(); _fDuration.clear(); _fNotes.clear();
      setState(() { _fMachineId = null; _fNextDue = null; _fType = 'WEEKLY'; });
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الجدول'), backgroundColor: AppColors.neonGreen),
      );
      _tabs.animateTo(0);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الحفظ'), backgroundColor: AppColors.neonRed),
      );
    } finally { setState(() => _submitting = false); }
  }

  bool _isPastDue(dynamic d) {
    if (d == null) return false;
    try { return DateTime.parse(d.toString()).isBefore(DateTime.now()); } catch (_) { return false; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 4),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'جداول الصيانة'),
          TabBar(controller: _tabs,
              tabs: const [Tab(text: 'الجداول'), Tab(text: 'إضافة جدول')]),
          Expanded(
            child: TabBarView(controller: _tabs,
                children: [_buildList(), _buildForm()]),
          ),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return _loading
        ? const LoadingWidget()
        : _schedules.isEmpty
            ? const Center(child: Text('لا توجد جداول', textDirection: TextDirection.rtl))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _schedules.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final s = _schedules[i];
                    final typeColor = _typeColors[s['scheduleType']] ?? AppColors.textSecondary;
                    final pastDue = _isPastDue(s['nextDueDate']);
                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['title'] ?? '--',
                                        style: AppText.h3, textDirection: TextDirection.rtl),
                                    Text(s['machine']?['name'] ?? '--',
                                        style: AppText.caption, textDirection: TextDirection.rtl),
                                  ],
                                ),
                              ),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                      _typeLabels[s['scheduleType']] ?? s['scheduleType'] ?? '--',
                                      style: AppText.label.copyWith(color: typeColor)),
                                ),
                                Switch(
                                  value: s['isActive'] ?? true,
                                  onChanged: (_) => _toggleActive(s as Map<String, dynamic>),
                                  activeColor: AppColors.neonGreen,
                                ),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            textDirection: TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Icon(Icons.calendar_today_outlined,
                                    color: pastDue ? AppColors.neonRed : AppColors.textSecondary,
                                    size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  s['nextDueDate'] != null
                                      ? _dateFmt.format(DateTime.parse(s['nextDueDate'].toString()))
                                      : '--',
                                  style: AppText.caption.copyWith(
                                      color: pastDue ? AppColors.neonRed : AppColors.textSecondary),
                                  textDirection: TextDirection.rtl,
                                ),
                              ]),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.neonRed, size: 20),
                                onPressed: () => _delete(s['id'].toString()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(children: [
          _label('الآلة *'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String>(
              value: _fMachineId,
              isExpanded: true,
              underline: const SizedBox(),
              hint: const Text('اختر الآلة', textDirection: TextDirection.rtl),
              items: _machines
                  .map((m) => DropdownMenuItem<String>(
                      value: m['id'].toString(),
                      child: Text(m['name'] ?? '--', textDirection: TextDirection.rtl)))
                  .toList(),
              onChanged: (v) => setState(() => _fMachineId = v),
            ),
          ),
          const SizedBox(height: 12),
          _field(_fTitle, 'العنوان *'),
          const SizedBox(height: 12),
          _field(_fDesc, 'الوصف', maxLines: 2),
          const SizedBox(height: 12),
          _label('نوع الجدول'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String>(
              value: _fType,
              isExpanded: true,
              underline: const SizedBox(),
              items: _types
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_typeLabels[t] ?? t, textDirection: TextDirection.rtl)))
                  .toList(),
              onChanged: (v) => setState(() => _fType = v ?? 'WEEKLY'),
            ),
          ),
          const SizedBox(height: 12),
          _label('تاريخ الاستحقاق التالي *'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                  color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
              child: Row(textDirection: TextDirection.rtl, children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.neonCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  _fNextDue != null ? _dateFmt.format(_fNextDue!) : 'اختر التاريخ',
                  style: AppText.body.copyWith(
                      color: _fNextDue != null ? AppColors.textPrimary : AppColors.textSecondary),
                  textDirection: TextDirection.rtl,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _field(_fDuration, 'المدة التقديرية (بالدقائق)', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _field(_fNotes, 'ملاحظات', maxLines: 3),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إنشاء الجدول',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppText.caption, textDirection: TextDirection.rtl),
      );

  Widget _field(TextEditingController ctrl, String label,
          {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.bgCard,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      );
}
