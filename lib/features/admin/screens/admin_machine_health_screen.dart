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

class AdminMachineHealthScreen extends StatefulWidget {
  const AdminMachineHealthScreen({super.key});
  @override
  State<AdminMachineHealthScreen> createState() => _AdminMachineHealthScreenState();
}

class _AdminMachineHealthScreenState extends State<AdminMachineHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _records = [];
  List<dynamic> _machines = [];
  bool _loading = true;
  String? _filterMachineId;

  // form
  String? _fMachineId;
  String _fOilLevel = 'GOOD';
  String _fCondition = 'GOOD';
  String _fVibration = 'LOW';
  String _fNoise = 'LOW';
  bool _fMaintNeeded = false;
  DateTime _fCheckDate = DateTime.now();
  final _fTemp = TextEditingController();
  final _fNotes = TextEditingController();
  bool _submitting = false;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  static const _oilLevels = {'GOOD': 'جيد', 'LOW': 'منخفض', 'CRITICAL': 'حرج'};
  static const _conditions = {
    'EXCELLENT': 'ممتاز', 'GOOD': 'جيد', 'FAIR': 'مقبول', 'POOR': 'سيئ', 'CRITICAL': 'حرج',
  };
  static const _levels = {'LOW': 'منخفض', 'MEDIUM': 'متوسط', 'HIGH': 'مرتفع'};

  Color _conditionColor(String? c) {
    switch (c) {
      case 'EXCELLENT': return AppColors.neonGreen;
      case 'GOOD':      return AppColors.neonCyan;
      case 'FAIR':      return AppColors.neonGold;
      case 'POOR':      return AppColors.neonOrange;
      case 'CRITICAL':  return AppColors.neonRed;
      default:          return AppColors.textSecondary;
    }
  }

  Color _oilColor(String? o) {
    switch (o) {
      case 'GOOD':     return AppColors.neonGreen;
      case 'LOW':      return AppColors.neonGold;
      case 'CRITICAL': return AppColors.neonRed;
      default:         return AppColors.textSecondary;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _fTemp.dispose();
    _fNotes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/machine-health'),
        ApiService.get('/machines/'),
      ]);
      final d0 = results[0].data;
      final d1 = results[1].data;
      setState(() {
        _records = d0 is List ? d0 : (d0['records'] ?? d0['data'] ?? []);
        _machines = d1 is List ? d1 : (d1['machines'] ?? d1['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  List<dynamic> get _filtered => _filterMachineId == null
      ? _records
      : _records.where((r) => r['machineId']?.toString() == _filterMachineId).toList();

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('تأكيد الحذف', style: AppText.h3, textDirection: TextDirection.rtl),
        content: const Text('هل تريد حذف هذا السجل؟', style: AppText.body,
            textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
        ],
      ),
    );
    if (ok == true) {
      try { await ApiService.delete('/machine-health/$id'); _load(); } catch (_) {}
    }
  }

  Future<void> _editRecord(Map<String, dynamic> r) async {
    String oilLevel = r['oilLevel'] ?? 'GOOD';
    String condition = r['overallCondition'] ?? 'GOOD';
    bool maintNeeded = r['maintenanceNeeded'] ?? false;
    final notesCtrl = TextEditingController(text: r['notes'] ?? '');
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('تعديل الفحص', style: AppText.h3),
                const SizedBox(height: 12),
                _ddSheet('حالة الزيت', _oilLevels, oilLevel, (v) => ss(() => oilLevel = v!)),
                const SizedBox(height: 8),
                _ddSheet('الحالة العامة', _conditions, condition,
                    (v) => ss(() => condition = v!)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: _dec('ملاحظات'),
                  maxLines: 2,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                Row(textDirection: TextDirection.rtl, children: [
                  Switch(
                    value: maintNeeded,
                    onChanged: (v) => ss(() => maintNeeded = v),
                    activeThumbColor: AppColors.neonOrange,
                  ),
                  const SizedBox(width: 8),
                  const Text('يحتاج صيانة', style: AppText.body,
                      textDirection: TextDirection.rtl),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.patch('/machine-health/${r['id']}', data: {
                          'oilLevel': oilLevel,
                          'overallCondition': condition,
                          'maintenanceNeeded': maintNeeded,
                          if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text,
                        });
                        _load();
                      } catch (_) {}
                    },
                    child: const Text('حفظ',
                        style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fCheckDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _fCheckDate = d);
  }

  Future<void> _submit() async {
    if (_fMachineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الآلة'), backgroundColor: AppColors.neonRed),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.post('/machine-health', data: {
        'machineId': _fMachineId,
        'checkDate': _fCheckDate.toIso8601String(),
        'oilLevel': _fOilLevel,
        'overallCondition': _fCondition,
        'vibrationLevel': _fVibration,
        'noiseLevel': _fNoise,
        'maintenanceNeeded': _fMaintNeeded,
        if (_fTemp.text.isNotEmpty) 'temperature': double.tryParse(_fTemp.text),
        if (_fNotes.text.isNotEmpty) 'notes': _fNotes.text,
      });
      _fTemp.clear(); _fNotes.clear();
      setState(() {
        _fMachineId = null; _fOilLevel = 'GOOD'; _fCondition = 'GOOD';
        _fVibration = 'LOW'; _fNoise = 'LOW'; _fMaintNeeded = false;
        _fCheckDate = DateTime.now();
      });
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الفحص'), backgroundColor: AppColors.neonGreen),
      );
      _tabs.animateTo(0);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الحفظ'), backgroundColor: AppColors.neonRed),
      );
    } finally { setState(() => _submitting = false); }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label, filled: true, fillColor: AppColors.bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );

  Widget _ddSheet(String label, Map<String, String> opts, String value,
      void Function(String?) onChange) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.caption, textDirection: TextDirection.rtl),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
          child: DropdownButton<String>(
            value: value, isExpanded: true, underline: const SizedBox(),
            items: opts.entries
                .map((e) => DropdownMenuItem(
                    value: e.key, child: Text(e.value, textDirection: TextDirection.rtl)))
                .toList(),
            onChanged: onChange,
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 4),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'صحة الآلات'),
          TabBar(controller: _tabs,
              tabs: const [Tab(text: 'سجلات الفحص'), Tab(text: 'إضافة فحص')]),
          Expanded(
            child: TabBarView(controller: _tabs,
                children: [_buildList(), _buildForm()]),
          ),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String?>(
              value: _filterMachineId, isExpanded: true, underline: const SizedBox(),
              hint: const Text('كل الآلات', textDirection: TextDirection.rtl),
              items: [
                const DropdownMenuItem<String?>(value: null,
                    child: Text('كل الآلات', textDirection: TextDirection.rtl)),
                ..._machines.map((m) => DropdownMenuItem<String?>(
                    value: m['id'].toString(),
                    child: Text(m['name'] ?? '--', textDirection: TextDirection.rtl))),
              ],
              onChanged: (v) => setState(() => _filterMachineId = v),
            ),
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? const LoadingWidget()
            : _filtered.isEmpty
                ? const Center(
                    child: Text('لا توجد سجلات', textDirection: TextDirection.rtl))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = _filtered[i];
                        final cColor = _conditionColor(r['overallCondition'] as String?);
                        final oColor = _oilColor(r['oilLevel'] as String?);
                        return GestureDetector(
                          onTap: () => _editRecord(r as Map<String, dynamic>),
                          onLongPress: () => _delete(r['id'].toString()),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['machine']?['name'] ?? '--',
                                          style: AppText.h3, textDirection: TextDirection.rtl),
                                      const SizedBox(height: 4),
                                      Row(textDirection: TextDirection.rtl, children: [
                                        Text('الزيت: ', style: AppText.caption),
                                        Text(
                                            _oilLevels[r['oilLevel']] ??
                                                r['oilLevel'] ?? '--',
                                            style: AppText.caption.copyWith(color: oColor),
                                            textDirection: TextDirection.rtl),
                                        if (r['temperature'] != null) ...[
                                          const SizedBox(width: 10),
                                          Text('${r['temperature']}°C',
                                              style: AppText.caption,
                                              textDirection: TextDirection.rtl),
                                        ],
                                      ]),
                                      if (r['recordedBy'] != null)
                                        Text('بواسطة: ${r['recordedBy']?['fullName'] ?? '--'}',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                      Text(
                                        r['checkDate'] != null
                                            ? _dateFmt.format(
                                                DateTime.parse(r['checkDate'].toString()))
                                            : '--',
                                        style: AppText.caption,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: cColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                          _conditions[r['overallCondition']] ??
                                              r['overallCondition'] ?? '--',
                                          style: AppText.label.copyWith(color: cColor)),
                                    ),
                                    if (r['maintenanceNeeded'] == true) ...[
                                      const SizedBox(height: 6),
                                      const Icon(Icons.warning_amber,
                                          color: AppColors.neonOrange, size: 18),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(children: [
          _label('الآلة *'),
          _dd(_machines, _fMachineId, 'اختر الآلة',
              (v) => setState(() => _fMachineId = v)),
          const SizedBox(height: 12),
          _label('تاريخ الفحص'),
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
                Text(_dateFmt.format(_fCheckDate),
                    style: AppText.body, textDirection: TextDirection.rtl),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _ddRow('حالة الزيت', _oilLevels, _fOilLevel,
              (v) => setState(() => _fOilLevel = v!)),
          const SizedBox(height: 12),
          _ddRow('الحالة العامة', _conditions, _fCondition,
              (v) => setState(() => _fCondition = v!)),
          const SizedBox(height: 12),
          _ddRow('مستوى الاهتزاز', _levels, _fVibration,
              (v) => setState(() => _fVibration = v!)),
          const SizedBox(height: 12),
          _ddRow('مستوى الضوضاء', _levels, _fNoise,
              (v) => setState(() => _fNoise = v!)),
          const SizedBox(height: 12),
          TextField(
            controller: _fTemp,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'درجة الحرارة °C (اختياري)', filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fNotes, maxLines: 3, textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'ملاحظات', filled: true, fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(textDirection: TextDirection.rtl, children: [
            Switch(
              value: _fMaintNeeded,
              onChanged: (v) => setState(() => _fMaintNeeded = v),
              activeThumbColor: AppColors.neonOrange,
            ),
            const SizedBox(width: 8),
            const Text('يحتاج صيانة', style: AppText.body, textDirection: TextDirection.rtl),
          ]),
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
                  : const Text('حفظ الفحص',
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

  Widget _dd(List<dynamic> machines, String? value, String hint,
      void Function(String?) onChange) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
        child: DropdownButton<String>(
          value: value, isExpanded: true, underline: const SizedBox(),
          hint: Text(hint, textDirection: TextDirection.rtl),
          items: machines
              .map((m) => DropdownMenuItem<String>(
                  value: m['id'].toString(),
                  child: Text(m['name'] ?? '--', textDirection: TextDirection.rtl)))
              .toList(),
          onChanged: onChange,
        ),
      );

  Widget _ddRow(String label, Map<String, String> opts, String value,
      void Function(String?) onChange) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
          child: DropdownButton<String>(
            value: value, isExpanded: true, underline: const SizedBox(),
            items: opts.entries
                .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, textDirection: TextDirection.rtl)))
                .toList(),
            onChanged: onChange,
          ),
        ),
      ]);
}
