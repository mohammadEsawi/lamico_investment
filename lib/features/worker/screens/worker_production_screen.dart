import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/worker_nav.dart';

class WorkerProductionScreen extends StatefulWidget {
  const WorkerProductionScreen({super.key});
  @override
  State<WorkerProductionScreen> createState() => _WorkerProductionScreenState();
}

class _WorkerProductionScreenState extends State<WorkerProductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _shifts   = [];
  List<dynamic> _machines = [];
  List<dynamic> _records  = [];
  bool _loading = true;
  String? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/shifts'),
        ApiService.get('/machines'),
        ApiService.get('/production/me'),
      ]);

      final shiftRaw   = results[0].data;
      final machineRaw = results[1].data;
      final recordRaw  = results[2].data;

      final shifts   = shiftRaw   is List ? shiftRaw   : (shiftRaw['shifts']     ?? shiftRaw['data']   ?? []);
      final machines = machineRaw is List ? machineRaw : (machineRaw['machines'] ?? machineRaw['data'] ?? []);
      final records  = recordRaw  is List ? recordRaw  : (recordRaw['records']   ?? recordRaw['data']  ?? []);

      final hour = DateTime.now().hour;
      String? autoId;
      for (final s in shifts) {
        final name = s['name'] as String? ?? '';
        if (name == 'A' && hour >= 0  && hour < 8)  { autoId = s['id'].toString(); break; }
        if (name == 'B' && hour >= 8  && hour < 16) { autoId = s['id'].toString(); break; }
        if (name == 'C' && hour >= 16)               { autoId = s['id'].toString(); break; }
      }

      setState(() {
        _shifts   = shifts;
        _machines = machines;
        _records  = records;
        _selectedShiftId = autoId ?? (shifts.isNotEmpty ? shifts[0]['id'].toString() : null);
        _loading  = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  List<dynamic> _machinesOf(String type) {
    final f = _machines.where((m) =>
        (m['type'] as String? ?? '').toUpperCase() == type).toList();
    return f.isEmpty ? _machines : f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const WorkerNav(selectedIndex: 1),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الإنتاج'),
          if (!_loading) _shiftBar(),
          Container(
            color: AppColors.bgCard,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.neonOrange,
              labelColor: AppColors.neonOrange,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.inbox_outlined),    text: 'الأغطية'),
                Tab(icon: Icon(Icons.science_outlined),  text: 'المخال'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : TabBarView(
                    controller: _tab,
                    children: [
                      _ProductionTab(
                        key: const ValueKey('caps'),
                        isCaps: true,
                        shiftId: _selectedShiftId,
                        machines: _machinesOf('CAPS'),
                        records: _records,
                        onSubmit: _load,
                      ),
                      _ProductionTab(
                        key: const ValueKey('preform'),
                        isCaps: false,
                        shiftId: _selectedShiftId,
                        machines: _machinesOf('PREFORM'),
                        records: _records,
                        onSubmit: _load,
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _shiftBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    color: AppColors.bgCard.withValues(alpha: 0.6),
    child: Row(
      textDirection: TextDirection.rtl,
      children: [
        const Icon(Icons.schedule, color: AppColors.neonCyan, size: 18),
        const SizedBox(width: 8),
        Text('الشفت:', style: AppText.caption),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<String>(
            value: _selectedShiftId,
            isExpanded: true,
            dropdownColor: AppColors.bgCard,
            underline: const SizedBox(),
            style: AppText.body.copyWith(color: AppColors.textPrimary),
            items: _shifts.map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(
              value: s['id'].toString(),
              child: Text('شفت ${s['name']}',
                  textDirection: TextDirection.rtl,
                  style: AppText.body.copyWith(color: AppColors.textPrimary)),
            )).toList(),
            onChanged: (v) => setState(() => _selectedShiftId = v),
          ),
        ),
      ],
    ),
  );
}

// ─── Production Tab ───────────────────────────────────────────────────────────

class _ProductionTab extends StatefulWidget {
  final bool isCaps;
  final String? shiftId;
  final List<dynamic> machines;
  final List<dynamic> records;
  final VoidCallback onSubmit;

  const _ProductionTab({
    super.key,
    required this.isCaps,
    required this.shiftId,
    required this.machines,
    required this.records,
    required this.onSubmit,
  });

  @override
  State<_ProductionTab> createState() => _ProductionTabState();
}

class _ProductionTabState extends State<_ProductionTab> {
  final _hdpeCtrl     = TextEditingController();
  final _ldpeCtrl     = TextEditingController();
  final _cartonsCtrl  = TextEditingController();
  final _capsCtrl     = TextEditingController();
  final _petCtrl      = TextEditingController();
  final _moldsCtrl    = TextEditingController();
  final _cavitiesCtrl = TextEditingController();
  final _cyclesCtrl   = TextEditingController();
  final _notesCtrl    = TextEditingController();

  String? _machineId;
  bool _submitting = false;

  int get _totalCaps {
    final c = int.tryParse(_cartonsCtrl.text) ?? 0;
    final p = int.tryParse(_capsCtrl.text) ?? 0;
    return c * p;
  }

  int get _totalPreforms {
    final m  = int.tryParse(_moldsCtrl.text) ?? 0;
    final ca = int.tryParse(_cavitiesCtrl.text) ?? 0;
    final cy = int.tryParse(_cyclesCtrl.text) ?? 0;
    return m * ca * cy;
  }

  @override
  void initState() {
    super.initState();
    if (widget.machines.isNotEmpty) {
      _machineId = widget.machines.first['id'].toString();
    }
    for (final c in [_cartonsCtrl, _capsCtrl, _moldsCtrl, _cavitiesCtrl, _cyclesCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_hdpeCtrl, _ldpeCtrl, _cartonsCtrl, _capsCtrl,
                     _petCtrl, _moldsCtrl, _cavitiesCtrl, _cyclesCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.shiftId == null) { _snack('اختر الشفت أولاً', err: true); return; }

    if (widget.isCaps) {
      if ((int.tryParse(_cartonsCtrl.text) ?? 0) == 0 ||
          (int.tryParse(_capsCtrl.text) ?? 0) == 0) {
        _snack('أدخل عدد الكراتين وعدد الأغطية/كرتونة', err: true); return;
      }
    } else {
      if ((int.tryParse(_moldsCtrl.text) ?? 0) == 0 ||
          (int.tryParse(_cavitiesCtrl.text) ?? 0) == 0 ||
          (int.tryParse(_cyclesCtrl.text) ?? 0) == 0) {
        _snack('أدخل عدد المخالات والكافيتي والدورات', err: true); return;
      }
    }

    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'shiftId' : int.parse(widget.shiftId!),
        'hourSlot': '${DateTime.now().hour.toString().padLeft(2, '0')}:00',
        'notes'   : _notesCtrl.text.trim(),
      };

      if (_machineId != null) body['machineId'] = int.parse(_machineId!);

      if (widget.isCaps) {
        final cartons   = int.tryParse(_cartonsCtrl.text) ?? 0;
        final perCarton = int.tryParse(_capsCtrl.text) ?? 0;
        body['rawHdpeUsed'] = double.tryParse(_hdpeCtrl.text) ?? 0.0;
        body['rawLdpeUsed'] = double.tryParse(_ldpeCtrl.text) ?? 0.0;
        // boxes: cavities=capsPerCarton, cycles=1, numberOfBoxes=cartons
        body['boxes'] = [{'cavities': perCarton, 'cycles': 1, 'numberOfBoxes': cartons}];
      } else {
        final molds    = int.tryParse(_moldsCtrl.text) ?? 0;
        final cavities = int.tryParse(_cavitiesCtrl.text) ?? 0;
        final cycles   = int.tryParse(_cyclesCtrl.text) ?? 0;
        body['rawPetUsed'] = double.tryParse(_petCtrl.text) ?? 0.0;
        body['boxes'] = [{'cavities': cavities, 'cycles': cycles, 'numberOfBoxes': molds}];
      }

      await ApiService.post('/production', data: body);

      for (final c in [_hdpeCtrl, _ldpeCtrl, _cartonsCtrl, _capsCtrl,
                       _petCtrl, _moldsCtrl, _cavitiesCtrl, _cyclesCtrl, _notesCtrl]) {
        c.clear();
      }
      _snack('تم تسجيل الإنتاج بنجاح ✓');
      widget.onSubmit();
    } catch (_) {
      _snack('فشل التسجيل — تحقق من البيانات', err: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: err ? AppColors.neonRed : AppColors.neonGreen,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isCaps ? AppColors.neonOrange : AppColors.neonCyan;
    final total = widget.isCaps ? _totalCaps : _totalPreforms;
    final label = widget.isCaps ? 'الأغطية' : 'المخال';

    return ListView(padding: const EdgeInsets.all(16), children: [
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(textDirection: TextDirection.rtl, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.isCaps ? Icons.inbox_outlined : Icons.science_outlined,
                color: color, size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text('تسجيل إنتاج $label', style: AppText.h3),
          ]),
          const SizedBox(height: 16),

          // Machine
          if (widget.machines.isNotEmpty) ...[
            _lbl('الماكينة'),
            _drop(color),
            const SizedBox(height: 14),
          ],

          // Caps
          if (widget.isCaps) ...[
            _lbl('المواد الخام'),
            Row(textDirection: TextDirection.rtl, children: [
              Expanded(child: _f(_hdpeCtrl, 'HDPE (كغ)', color)),
              const SizedBox(width: 10),
              Expanded(child: _f(_ldpeCtrl, 'LDPE (كغ)', color)),
            ]),
            const SizedBox(height: 14),
            _lbl('الإنتاج'),
            Row(textDirection: TextDirection.rtl, children: [
              Expanded(child: _f(_cartonsCtrl, 'عدد الكراتين', color)),
              const SizedBox(width: 10),
              Expanded(child: _f(_capsCtrl, 'أغطية/كرتونة', color)),
            ]),
          ],

          // Preform
          if (!widget.isCaps) ...[
            _lbl('استهلاك المادة الخام'),
            _f(_petCtrl, 'كمية PET (كغ)', color),
            const SizedBox(height: 14),
            _lbl('بيانات الإنتاج'),
            _f(_moldsCtrl, 'عدد المخالات', color),
            const SizedBox(height: 8),
            Row(textDirection: TextDirection.rtl, children: [
              Expanded(child: _f(_cavitiesCtrl, 'عدد الكافيتي', color)),
              const SizedBox(width: 10),
              Expanded(child: _f(_cyclesCtrl, 'عدد الدورات', color)),
            ]),
          ],

          const SizedBox(height: 14),

          // Total box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الإجمالي المحسوب',
                      style: AppText.caption.copyWith(color: color),
                      textDirection: TextDirection.rtl),
                  const SizedBox(height: 2),
                  Text(
                    widget.isCaps
                        ? '${_cartonsCtrl.text.isEmpty ? "0" : _cartonsCtrl.text} × ${_capsCtrl.text.isEmpty ? "0" : _capsCtrl.text}'
                        : '${_moldsCtrl.text.isEmpty ? "0" : _moldsCtrl.text} × ${_cavitiesCtrl.text.isEmpty ? "0" : _cavitiesCtrl.text} × ${_cyclesCtrl.text.isEmpty ? "0" : _cyclesCtrl.text}',
                    style: AppText.label.copyWith(color: AppColors.textSecondary),
                    textDirection: TextDirection.rtl,
                  ),
                ]),
                Text('$total',
                    style: AppText.h1.copyWith(color: color, fontSize: 30)),
              ],
            ),
          ),

          const SizedBox(height: 14),
          _f(_notesCtrl, 'ملاحظات (اختياري)', AppColors.textSecondary,
              type: TextInputType.text),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('تسجيل إنتاج $label',
                      style: const TextStyle(fontFamily: 'Cairo',
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 20),

      if (widget.records.isNotEmpty) ...[
        Row(textDirection: TextDirection.rtl, children: [
          const Icon(Icons.history, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 6),
          Text('آخر السجلات', style: AppText.h3),
        ]),
        const SizedBox(height: 10),
        ...widget.records.take(15).map((r) => _RecordCard(record: r, color: color)),
      ],
    ]);
  }

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t,
        style: AppText.caption.copyWith(color: AppColors.textSecondary),
        textDirection: TextDirection.rtl),
  );

  Widget _f(TextEditingController c, String hint, Color color,
      {TextInputType type = TextInputType.number}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: c,
        keyboardType: type,
        textAlign: TextAlign.right,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );

  Widget _drop(Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: DropdownButton<String>(
      value: _machineId,
      isExpanded: true,
      dropdownColor: AppColors.bgCard,
      underline: const SizedBox(),
      items: widget.machines.map<DropdownMenuItem<String>>((m) => DropdownMenuItem<String>(
        value: m['id'].toString(),
        child: Text(m['name'] ?? '--',
            textDirection: TextDirection.rtl,
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      )).toList(),
      onChanged: (v) => setState(() => _machineId = v),
    ),
  );
}

// ─── Record Card ──────────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final Color color;
  const _RecordCard({required this.record, required this.color});

  @override
  Widget build(BuildContext context) {
    final date    = (record['date'] ?? record['createdAt'] ?? '').toString();
    final dateStr = date.length >= 10 ? date.substring(0, 10) : date;
    final shift   = record['shift']?['name'] ?? '--';
    final total   = record['totalPieces'] ?? 0;
    final cartons = record['cartonsCount'] ?? 0;
    final hdpe    = record['rawHdpeUsed'];
    final ldpe    = record['rawLdpeUsed'];
    final pet     = record['rawPetUsed'];
    final machine = record['machine']?['name'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(textDirection: TextDirection.rtl, children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dateStr, style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                      textDirection: TextDirection.rtl),
                  Text('شفت $shift${machine != null ? " — $machine" : ""}',
                      style: AppText.caption, textDirection: TextDirection.rtl),
                ]),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$total قطعة',
                    style: AppText.h3.copyWith(color: color),
                    textDirection: TextDirection.rtl),
                if (cartons > 0)
                  Text('$cartons كرتونة',
                      style: AppText.caption, textDirection: TextDirection.rtl),
              ]),
            ],
          ),
          if (hdpe != null || ldpe != null || pet != null) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              if (hdpe != null) _chip('HDPE: $hdpe كغ', AppColors.neonGreen),
              if (ldpe != null) _chip('LDPE: $ldpe كغ', AppColors.neonBlue),
              if (pet  != null) _chip('PET: $pet كغ',   AppColors.neonCyan),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(t, style: AppText.label.copyWith(color: c),
        textDirection: TextDirection.rtl),
  );
}
