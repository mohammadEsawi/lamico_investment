import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/worker_nav.dart';

// ── Row models ────────────────────────────────────────────────────────────────

class _InvRow {
  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController notes;
  final bool fixed;

  _InvRow({String? fixedName})
      : name = TextEditingController(text: fixedName ?? ''),
        qty = TextEditingController(),
        notes = TextEditingController(),
        fixed = fixedName != null;

  void dispose() {
    name.dispose();
    qty.dispose();
    notes.dispose();
  }
}

class _RawRow {
  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController notes;
  String unit;
  final bool fixed;

  _RawRow({String? fixedName, this.unit = 'كجم'})
      : name = TextEditingController(text: fixedName ?? ''),
        qty = TextEditingController(),
        notes = TextEditingController(),
        fixed = fixedName != null;

  void dispose() {
    name.dispose();
    qty.dispose();
    notes.dispose();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class WorkerDailyInventoryScreen extends StatefulWidget {
  const WorkerDailyInventoryScreen({super.key});

  @override
  State<WorkerDailyInventoryScreen> createState() =>
      _WorkerDailyInventoryScreenState();
}

class _WorkerDailyInventoryScreenState
    extends State<WorkerDailyInventoryScreen> {
  late List<_InvRow> _caps;
  late List<_InvRow> _preforms;
  late List<_RawRow> _raw;

  List<dynamic> _shifts = [];
  String? _shiftId;
  double? _lastElec;
  final _elecCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resetRows();
    _load();
  }

  void _resetRows() {
    _caps = [
      _InvRow(fixedName: 'أغطية صغيرة'),
      _InvRow(fixedName: 'أغطية كبيرة'),
    ];
    _preforms = [
      _InvRow(fixedName: 'بريفورم 500 مل'),
      _InvRow(fixedName: 'بريفورم 1.5 لتر'),
      _InvRow(fixedName: 'بريفورم 2 لتر'),
    ];
    _raw = [
      _RawRow(fixedName: 'PET', unit: 'كجم'),
      _RawRow(fixedName: 'ماستر باتش', unit: 'كجم'),
      _RawRow(fixedName: 'مواد تعبئة', unit: 'كجم'),
    ];
  }

  @override
  void dispose() {
    for (final r in _caps) { r.dispose(); }
    for (final r in _preforms) { r.dispose(); }
    for (final r in _raw) { r.dispose(); }
    _elecCtrl.dispose();
    super.dispose();
  }

  // ── API ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/shifts'),
        ApiService.get('/electricity/readings'),
      ]);

      final sr = results[0].data;
      final rr = results[1].data;
      final shifts =
          sr is List ? sr : (sr['shifts'] ?? sr['data'] ?? <dynamic>[]);
      final readings =
          rr is List ? rr : (rr['readings'] ?? rr['data'] ?? <dynamic>[]);

      final hour = DateTime.now().hour;
      String? autoId;
      for (final s in shifts) {
        final n = (s['name'] as String? ?? '');
        if (n == 'A' && hour < 8) { autoId = s['id'].toString(); break; }
        if (n == 'B' && hour >= 8 && hour < 16) { autoId = s['id'].toString(); break; }
        if (n == 'C' && hour >= 16) { autoId = s['id'].toString(); break; }
      }

      double? lastElec;
      if ((readings as List).isNotEmpty) {
        final sorted = List<dynamic>.from(readings)
          ..sort((a, b) => (b['createdAt'] ?? b['date'] ?? '')
              .toString()
              .compareTo((a['createdAt'] ?? a['date'] ?? '').toString()));
        lastElec = (sorted.first['endReading'] as num?)?.toDouble();
      }

      setState(() {
        _shifts = shifts;
        _shiftId = autoId ??
            (shifts.isNotEmpty ? shifts[0]['id'].toString() : null);
        _lastElec = lastElec;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final items = <Map<String, dynamic>>[];

    void addInv(List<_InvRow> rows, String cat) {
      for (final r in rows) {
        final n = r.name.text.trim();
        final q = double.tryParse(r.qty.text.trim());
        if (n.isNotEmpty && q != null && q > 0) {
          items.add({
            'category': cat,
            'name': n,
            'quantity': q,
            'notes': r.notes.text.trim(),
          });
        }
      }
    }

    addInv(_caps, 'caps');
    addInv(_preforms, 'preforms');

    for (final r in _raw) {
      final n = r.name.text.trim();
      final q = double.tryParse(r.qty.text.trim());
      if (n.isNotEmpty && q != null && q > 0) {
        items.add({
          'category': 'raw_materials',
          'name': n,
          'quantity': q,
          'unit': r.unit,
          'notes': r.notes.text.trim(),
        });
      }
    }

    if (items.isEmpty) {
      _snack('أدخل كمية لصنف واحد على الأقل', err: true);
      return;
    }

    // Validate electricity
    final elecText = _elecCtrl.text.trim();
    final elecVal = elecText.isEmpty ? null : double.tryParse(elecText);
    if (elecText.isNotEmpty && elecVal == null) {
      _snack('قراءة العداد يجب أن تكون رقماً', err: true);
      return;
    }
    if (elecVal != null && _lastElec != null && elecVal <= _lastElec!) {
      _snack(
          'القراءة الجديدة يجب أن تكون أكبر من الأخيرة (${_lastElec!.toStringAsFixed(0)})',
          err: true);
      return;
    }

    // Electricity confirmation dialog
    if (elecVal != null) {
      final ok = await _confirmElec(elecVal);
      if (!ok) return;
    }

    // Final save confirmation
    final ok = await _confirmDialog(
      'تأكيد حفظ الجرد',
      'سيتم تسجيل ${items.length} صنف في الجرد اليومي.\nهل أنت متأكد؟',
      AppColors.neonGreen,
    );
    if (!ok) return;

    setState(() => _saving = true);
    try {
      await ApiService.post('/inventory/daily', data: {
        'date': DateTime.now().toIso8601String().substring(0, 10),
        if (_shiftId != null) 'shiftId': int.tryParse(_shiftId!),
        'items': items,
      });

      if (elecVal != null && _shiftId != null) {
        await ApiService.post('/electricity/readings', data: {
          'date': DateTime.now().toIso8601String(),
          'shiftId': int.parse(_shiftId!),
          'startReading': _lastElec ?? 0,
          'endReading': elecVal,
          'notes': 'الجرد اليومي',
        });
      }

      _elecCtrl.clear();
      for (final r in _caps) { r.qty.clear(); r.notes.clear(); }
      for (final r in _preforms) { r.qty.clear(); r.notes.clear(); }
      for (final r in _raw) { r.qty.clear(); r.notes.clear(); }

      _snack('تم حفظ الجرد اليومي بنجاح ✓');
      await _load();
    } catch (_) {
      _snack('فشل الحفظ — تأكد من الاتصال بالسيرفر', err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<bool> _confirmElec(double newVal) async {
    final cons = _lastElec != null
        ? (newVal - _lastElec!).toStringAsFixed(1)
        : '--';
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(textDirection: TextDirection.rtl, children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.neonGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.bolt, color: AppColors.neonGold, size: 20),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'تأكيد قراءة الكهرباء',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              _dRow('القراءة الأخيرة:',
                  _lastElec?.toStringAsFixed(0) ?? '--', AppColors.textSecondary),
              const SizedBox(height: 8),
              _dRow('القراءة الجديدة:', newVal.toStringAsFixed(0),
                  AppColors.neonBlue),
              const Divider(height: 20),
              _dRow('الاستهلاك:', '$cons كيلوواط', AppColors.neonGold),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neonGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'هل أنت متأكد من هذه القراءة؟',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('تعديل',
                    style: TextStyle(
                        fontFamily: 'Cairo', color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGold),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نعم، متأكد',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ==
        true;
  }

  Future<bool> _confirmDialog(String title, String msg, Color color) async =>
      await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(title,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              content: Text(msg,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Cairo')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('تأكيد',
                      style: TextStyle(
                          fontFamily: 'Cairo', color: Colors.white)),
                ),
              ],
            ),
          ) ==
          true;

  Widget _dRow(String label, String val, Color c) => Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                  fontSize: 14),
              textDirection: TextDirection.rtl),
          Text(val,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  color: c,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
              textDirection: TextDirection.rtl),
        ],
      );

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: err ? AppColors.neonRed : AppColors.neonGreen,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const WorkerNav(selectedIndex: 3),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(
            title: 'الجرد اليومي',
            actions: [const WorkerMoreMenu()],
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                      children: [
                        _headerCard(dateStr),
                        const SizedBox(height: 12),
                        _invSection(
                          title: 'الأغطية',
                          icon: Icons.inbox_outlined,
                          color: AppColors.neonOrange,
                          rows: _caps,
                          unit: 'أصناف',
                          onAdd: () =>
                              setState(() => _caps.add(_InvRow())),
                          onRemove: (i) =>
                              setState(() => _caps.removeAt(i)),
                        ),
                        const SizedBox(height: 10),
                        _invSection(
                          title: 'البريفورم',
                          icon: Icons.science_outlined,
                          color: AppColors.neonCyan,
                          rows: _preforms,
                          unit: 'أصناف',
                          onAdd: () =>
                              setState(() => _preforms.add(_InvRow())),
                          onRemove: (i) =>
                              setState(() => _preforms.removeAt(i)),
                        ),
                        const SizedBox(height: 10),
                        _rawSection(),
                        const SizedBox(height: 10),
                        _elecSection(),
                        const SizedBox(height: 20),
                        _saveBtn(),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _headerCard(String dateStr) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(textDirection: TextDirection.rtl, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today,
                color: AppColors.neonBlue, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dateStr,
                style: AppText.h3, textDirection: TextDirection.rtl),
            Text('الجرد اليومي',
                style: AppText.caption, textDirection: TextDirection.rtl),
          ]),
          const Spacer(),
          if (_shifts.isNotEmpty)
            DropdownButton<String>(
              value: _shiftId,
              dropdownColor: AppColors.bgCard,
              underline: const SizedBox(),
              style: AppText.body.copyWith(color: AppColors.textPrimary),
              items: _shifts
                  .map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                        value: s['id'].toString(),
                        child: Text('شفت ${s['name']}',
                            textDirection: TextDirection.rtl,
                            style: AppText.body
                                .copyWith(color: AppColors.textPrimary)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _shiftId = v),
            ),
        ]),
      );

  Widget _invSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_InvRow> rows,
    required String unit,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) =>
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader(title, icon, color, rows.length, unit),
          const SizedBox(height: 10),
          _colHeader3(['الصنف', 'الكمية', 'ملاحظات']),
          const Divider(color: Colors.white24, height: 12),
          ...rows.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(textDirection: TextDirection.rtl, children: [
                Expanded(
                    flex: 4,
                    child: r.fixed
                        ? _fixedCell(r.name.text, color)
                        : _inputCell(r.name, color, 'اسم الصنف')),
                const SizedBox(width: 5),
                Expanded(
                    flex: 2,
                    child: _inputCell(r.qty, color, '0', number: true)),
                const SizedBox(width: 5),
                Expanded(
                    flex: 3,
                    child:
                        _inputCell(r.notes, AppColors.textMuted, 'ملاحظة')),
                const SizedBox(width: 4),
                r.fixed
                    ? const SizedBox(width: 22)
                    : GestureDetector(
                        onTap: () => onRemove(i),
                        child: const Icon(Icons.remove_circle_outline,
                            color: AppColors.neonRed, size: 20)),
              ]),
            );
          }),
          _addBtn('إضافة صنف', color, onAdd),
        ]),
      );

  Widget _rawSection() {
    const color = AppColors.neonGreen;
    return GlassCard(
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(
            'المواد الخام', Icons.inventory_2_outlined, color, _raw.length, 'مواد'),
        const SizedBox(height: 10),
        _colHeader4(['المادة', 'الكمية', 'الوحدة', 'ملاحظات']),
        const Divider(color: Colors.white24, height: 12),
        ..._raw.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(textDirection: TextDirection.rtl, children: [
              Expanded(
                  flex: 3,
                  child: r.fixed
                      ? _fixedCell(r.name.text, color)
                      : _inputCell(r.name, color, 'اسم المادة')),
              const SizedBox(width: 5),
              Expanded(
                  flex: 2,
                  child: _inputCell(r.qty, color, '0', number: true)),
              const SizedBox(width: 5),
              Expanded(flex: 2, child: _unitDrop(r, color)),
              const SizedBox(width: 5),
              Expanded(
                  flex: 3,
                  child:
                      _inputCell(r.notes, AppColors.textMuted, 'ملاحظة')),
              const SizedBox(width: 4),
              r.fixed
                  ? const SizedBox(width: 22)
                  : GestureDetector(
                      onTap: () => setState(() => _raw.removeAt(i)),
                      child: const Icon(Icons.remove_circle_outline,
                          color: AppColors.neonRed, size: 20)),
            ]),
          );
        }),
        _addBtn('إضافة مادة خام', color,
            () => setState(() => _raw.add(_RawRow()))),
      ]),
    );
  }

  Widget _elecSection() => GlassCard(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(textDirection: TextDirection.rtl, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neonGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt,
                  color: AppColors.neonGold, size: 22),
            ),
            const SizedBox(width: 10),
            Text('عداد الكهرباء', style: AppText.h3),
            const Spacer(),
            _chip('اختياري', AppColors.neonGold),
          ]),
          const SizedBox(height: 14),
          if (_lastElec != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.neonBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(textDirection: TextDirection.rtl, children: [
                    const Icon(Icons.history,
                        color: AppColors.neonBlue, size: 16),
                    const SizedBox(width: 6),
                    Text('آخر قراءة مسجلة:',
                        style: AppText.body,
                        textDirection: TextDirection.rtl),
                  ]),
                  Text('${_lastElec!.toStringAsFixed(0)} كيلوواط',
                      style: AppText.h3.copyWith(color: AppColors.neonBlue),
                      textDirection: TextDirection.rtl),
                ],
              ),
            ),
          _inputCell(_elecCtrl, AppColors.neonGold,
              'القراءة الحالية (كيلوواط)',
              number: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.neonGold.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(textDirection: TextDirection.rtl, children: [
              const Icon(Icons.info_outline,
                  color: AppColors.neonGold, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ستظهر نافذة تأكيد قبل تسجيل القراءة',
                  style:
                      AppText.label.copyWith(color: AppColors.neonGold),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ]),
          ),
        ]),
      );

  Widget _saveBtn() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Text('حفظ الجرد اليومي',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
        ),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(
          String title, IconData icon, Color color, int count, String unit) =>
      Row(textDirection: TextDirection.rtl, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppText.h3),
        const Spacer(),
        _chip('$count $unit', color),
      ]);

  Widget _colHeader3(List<String> cols) => Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
              flex: 4,
              child: Text(cols[0],
                  style:
                      AppText.label.copyWith(color: AppColors.textMuted),
                  textDirection: TextDirection.rtl)),
          const SizedBox(width: 5),
          Expanded(
              flex: 2,
              child: Text(cols[1],
                  style:
                      AppText.label.copyWith(color: AppColors.textMuted),
                  textDirection: TextDirection.rtl)),
          const SizedBox(width: 5),
          Expanded(
              flex: 3,
              child: Text(cols[2],
                  style:
                      AppText.label.copyWith(color: AppColors.textMuted),
                  textDirection: TextDirection.rtl)),
          const SizedBox(width: 26),
        ],
      );

  Widget _colHeader4(List<String> cols) => Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
              flex: 3,
              child: Text(cols[0],
                  style:
                      AppText.label.copyWith(color: AppColors.textMuted),
                  textDirection: TextDirection.rtl)),
          const SizedBox(width: 5),
          Expanded(
              flex: 2,
              child: Text(cols[1],
                  style:
                      AppText.label.copyWith(color: AppColors.textMuted),
                  textDirection: TextDirection.rtl)),
          const SizedBox(width: 5),
          Expanded(
              flex: 2,
              child: Text(cols[2],
                  style:
                      AppText.label.copyWith(color: AppColors.textMuted),
                  textDirection: TextDirection.rtl)),
          const SizedBox(width: 5),
          Expanded(
              flex: 3,
              child: Text(cols[3],
                  style:
                      AppText.label.copyWith(color: AppColors.textMuted),
                  textDirection: TextDirection.rtl)),
          const SizedBox(width: 26),
        ],
      );

  Widget _fixedCell(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: AppText.body,
            textDirection: TextDirection.rtl,
            overflow: TextOverflow.ellipsis),
      );

  Widget _inputCell(
    TextEditingController ctrl,
    Color color,
    String hint, {
    bool number = false,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType:
              number ? TextInputType.number : TextInputType.text,
          textAlign: TextAlign.right,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppText.caption.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 9),
          ),
        ),
      );

  Widget _unitDrop(_RawRow row, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: DropdownButton<String>(
          value: row.unit,
          isExpanded: true,
          dropdownColor: AppColors.bgCard,
          underline: const SizedBox(),
          style: AppText.caption.copyWith(color: AppColors.textPrimary),
          items: ['كجم', 'طن', 'لتر', 'علبة', 'قطعة']
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u,
                        textDirection: TextDirection.rtl,
                        style: AppText.caption
                            .copyWith(color: AppColors.textPrimary)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => row.unit = v ?? row.unit),
        ),
      );

  Widget _addBtn(String label, Color color, VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.add_circle_outline, color: color, size: 18),
        label: Text(label, style: AppText.body.copyWith(color: color)),
      );

  Widget _chip(String t, Color c) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t,
            style: AppText.label.copyWith(color: c),
            textDirection: TextDirection.rtl),
      );
}
