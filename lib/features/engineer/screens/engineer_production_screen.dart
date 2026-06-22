import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';

class EngineerProductionScreen extends StatefulWidget {
  const EngineerProductionScreen({super.key});
  @override
  State<EngineerProductionScreen> createState() => _EngineerProductionScreenState();
}

class _EngineerProductionScreenState extends State<EngineerProductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _shifts    = [];
  List<dynamic> _machines  = [];
  List<dynamic> _materials = [];
  List<dynamic> _records   = [];
  bool _loading        = true;
  bool _loadingRecords = true;
  String? _shiftId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
    _loadRecords();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadRecords() async {
    setState(() => _loadingRecords = true);
    try {
      final res = await ApiService.get('/production/me');
      final data = res.data;
      setState(() {
        _records = data is List ? data : (data['records'] ?? data['data'] ?? []);
        AppDate.sortDesc(_records);
        _loadingRecords = false;
      });
    } catch (_) { setState(() => _loadingRecords = false); }
  }

  Future<void> _deleteRecord(dynamic rec) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('حذف سجل الإنتاج'),
          content: const Text('هل تريد حذف هذا السجل نهائياً؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.delete('/production/${rec['id']}');
        _loadRecords();
      } catch (_) {}
    }
  }

  Widget _buildHistory() {
    if (_loadingRecords) return const LoadingWidget();
    if (_records.isEmpty) {
      return const Center(child: Text('لا توجد سجلات إنتاج',
          textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')));
    }
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        separatorBuilder: (_, i2) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = _records[i];
          final total = r['totalPieces'] ?? r['total'] ?? '--';
          final shift = r['shift']?['name'] ?? '--';
          final machine = r['machine']?['name'] ?? '--';
          return GlassCard(
            padding: const EdgeInsets.all(14),
            child: InkWell(
              onLongPress: () => _deleteRecord(r),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neonOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.factory_outlined, color: AppColors.neonOrange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('إجمالي: $total قطعة',
                          style: AppText.h3, textDirection: TextDirection.rtl),
                      Text('شفت $shift  —  $machine',
                          style: AppText.caption, textDirection: TextDirection.rtl),
                      Text(AppDate.format(r['createdAt'] ?? r['date']),
                          style: AppText.label.copyWith(color: AppColors.textSecondary),
                          textDirection: TextDirection.rtl),
                    ]),
                  ),
                  const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/shifts'),
        ApiService.get('/machines'),
        ApiService.get('/inventory/materials'),
      ]);

      final shiftRaw    = results[0].data;
      final machineRaw  = results[1].data;
      final materialRaw = results[2].data;

      final shifts    = shiftRaw    is List ? shiftRaw    : (shiftRaw['shifts']       ?? shiftRaw['data']    ?? []);
      final machines  = machineRaw  is List ? machineRaw  : (machineRaw['machines']   ?? machineRaw['data']  ?? []);
      final materials = materialRaw is List ? materialRaw : (materialRaw['materials'] ?? materialRaw['data'] ?? []);

      final hour = DateTime.now().hour;
      String? autoId;
      for (final s in shifts) {
        final name = s['name'] as String? ?? '';
        if (name == 'A' && hour >= 0  && hour < 8)  { autoId = s['id'].toString(); break; }
        if (name == 'B' && hour >= 8  && hour < 16) { autoId = s['id'].toString(); break; }
        if (name == 'C' && hour >= 16)               { autoId = s['id'].toString(); break; }
      }

      if (!mounted) return;
      setState(() {
        _shifts    = shifts;
        _machines  = machines;
        _materials = materials;
        _shiftId   = autoId ?? (shifts.isNotEmpty ? shifts[0]['id'].toString() : null);
        _loading   = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<dynamic> _machinesOf(String type) {
    final f = _machines.where((m) =>
        (m['type'] as String? ?? '').toUpperCase() == type).toList();
    return f.isEmpty ? _machines : f;
  }

  int? _findMaterialId(String keyword) {
    final m = _materials.cast<Map<String, dynamic>?>().firstWhere(
      (m) => (m!['name'] as String? ?? '').contains(keyword),
      orElse: () => null,
    );
    return m != null ? m['id'] as int? : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        AiAppBar(
          title: 'تسجيل الإنتاج',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: _load,
            ),
          ],
        ),
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
              Tab(icon: Icon(Icons.history),           text: 'السجلات'),
              Tab(icon: Icon(Icons.inbox_outlined),    text: 'الأغطية 🧢'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'المخال 🔩'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : TabBarView(
                  controller: _tab,
                  children: [
                    _buildHistory(),
                    _CapsTab(
                      key: const ValueKey('caps'),
                      shiftId: _shiftId,
                      machines: _machinesOf('CAPS'),
                      findMaterialId: _findMaterialId,
                    ),
                    _PreformTab(
                      key: const ValueKey('preform'),
                      shiftId: _shiftId,
                      machines: _machinesOf('PREFORM'),
                      findMaterialId: _findMaterialId,
                    ),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _shiftBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    color: AppColors.bgCard.withValues(alpha: 0.6),
    child: Row(textDirection: TextDirection.rtl, children: [
      const Icon(Icons.schedule, color: AppColors.neonCyan, size: 18),
      const SizedBox(width: 8),
      Text('الشفت:', style: AppText.caption),
      const SizedBox(width: 8),
      Expanded(
        child: DropdownButton<String>(
          value: _shiftId,
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
          onChanged: (v) => setState(() => _shiftId = v),
        ),
      ),
    ]),
  );
}

// ─── Caps Tab ─────────────────────────────────────────────────────────────────

class _CapsTab extends StatefulWidget {
  final String? shiftId;
  final List<dynamic> machines;
  final int? Function(String keyword) findMaterialId;

  const _CapsTab({
    super.key,
    required this.shiftId,
    required this.machines,
    required this.findMaterialId,
  });

  @override
  State<_CapsTab> createState() => _CapsTabState();
}

class _CapsTabState extends State<_CapsTab> {
  final _cartonsCtrl   = TextEditingController();
  final _capsCtrl      = TextEditingController();
  final _hdpeCtrl      = TextEditingController();
  final _ldpeCtrl      = TextEditingController();
  final _cartonsUsedCtrl = TextEditingController();
  final _colorCtrl     = TextEditingController();
  final _adhesiveCtrl  = TextEditingController();
  final _notesCtrl     = TextEditingController();

  String? _machineId;
  XFile? _photo;
  bool _submitting = false;

  int get _total {
    final c = int.tryParse(_cartonsCtrl.text) ?? 0;
    final p = int.tryParse(_capsCtrl.text) ?? 0;
    return c * p;
  }

  @override
  void initState() {
    super.initState();
    if (widget.machines.isNotEmpty) {
      _machineId = widget.machines.first['id'].toString();
    }
    _capsCtrl.text = '1000';
    for (final c in [_cartonsCtrl, _capsCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_cartonsCtrl, _capsCtrl, _hdpeCtrl, _ldpeCtrl,
                     _cartonsUsedCtrl, _colorCtrl, _adhesiveCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<ImageSource?> _showPhotoSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.neonCyan),
              title: Text('الكاميرا', style: AppText.body),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.neonPurple),
              title: Text('معرض الصور', style: AppText.body),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await _showPhotoSourceDialog();
    if (source == null) return;
    final img = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
    if (img != null && mounted) setState(() => _photo = img);
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.shiftId == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('اختر الشفت أولاً', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
      return;
    }
    final cartons = int.tryParse(_cartonsCtrl.text) ?? 0;
    final perCarton = int.tryParse(_capsCtrl.text) ?? 0;
    if (cartons == 0 || perCarton == 0) {
      messenger.showSnackBar(const SnackBar(
        content: Text('أدخل عدد الكراتين وعدد الأغطية/كرتونة', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      final hdpe     = double.tryParse(_hdpeCtrl.text) ?? 0.0;
      final ldpe     = double.tryParse(_ldpeCtrl.text) ?? 0.0;
      final cartUsed = double.tryParse(_cartonsUsedCtrl.text) ?? cartons.toDouble();
      final color    = double.tryParse(_colorCtrl.text) ?? 0.0;
      final adhesive = double.tryParse(_adhesiveCtrl.text) ?? 0.0;
      final boxesJson = jsonEncode([{'cavities': perCarton, 'cycles': 1, 'numberOfBoxes': cartons}]);
      final shiftId  = int.parse(widget.shiftId!);
      final hourSlot = '${DateTime.now().hour.toString().padLeft(2, '0')}:00';

      if (_photo != null) {
        final form = FormData.fromMap({
          'shiftId'        : shiftId,
          'hourSlot'       : hourSlot,
          'cartonsCount'   : cartons,
          'piecesPerCarton': perCarton,
          'totalPieces'    : cartons * perCarton,
          'rawHdpeUsed'    : hdpe,
          'rawLdpeUsed'    : ldpe,
          'colorUsed'      : color,
          'adhesiveUsed'   : adhesive,
          'boxes'          : boxesJson,
          'notes'          : _notesCtrl.text.trim(),
          if (_machineId != null) 'machineId': int.parse(_machineId!),
          'document'       : await MultipartFile.fromFile(_photo!.path, filename: _photo!.name),
        });
        await ApiService.postMultipart('/production', form);
      } else {
        await ApiService.post('/production', data: {
          'shiftId'        : shiftId,
          'hourSlot'       : hourSlot,
          'cartonsCount'   : cartons,
          'piecesPerCarton': perCarton,
          'totalPieces'    : cartons * perCarton,
          'rawHdpeUsed'    : hdpe,
          'rawLdpeUsed'    : ldpe,
          'colorUsed'      : color,
          'adhesiveUsed'   : adhesive,
          'boxes'          : [{'cavities': perCarton, 'cycles': 1, 'numberOfBoxes': cartons}],
          'notes'          : _notesCtrl.text.trim(),
          if (_machineId != null) 'machineId': int.parse(_machineId!),
        });
      }

      final deductions = <Future>[];
      void deduct(String keyword, double qty) {
        if (qty <= 0) return;
        final id = widget.findMaterialId(keyword);
        if (id == null) return;
        deductions.add(ApiService.post('/inventory/transactions', data: {
          'materialId'   : id,
          'type'         : 'OUT',
          'quantity'     : qty,
          'referenceType': 'PRODUCTION',
        }));
      }
      deduct('HDPE', hdpe);
      deduct('LDPE', ldpe);
      deduct('ماستر', color);
      deduct('لاصق', adhesive);
      deduct('كراتين', cartUsed);

      bool inventoryWarning = false;
      if (deductions.isNotEmpty) {
        try {
          await Future.wait(deductions);
        } catch (_) {
          inventoryWarning = true;
        }
      }

      if (!mounted) return;
      for (final c in [_cartonsCtrl, _capsCtrl, _hdpeCtrl, _ldpeCtrl,
                       _cartonsUsedCtrl, _colorCtrl, _adhesiveCtrl, _notesCtrl]) {
        c.clear();
      }
      _capsCtrl.text = '1000';
      setState(() => _photo = null);
      messenger.showSnackBar(SnackBar(
        content: Text(
          inventoryWarning
              ? 'تم تسجيل الإنتاج ✓ — تحذير: فشل خصم المخزون'
              : 'تم تسجيل الإنتاج بنجاح ✓',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: inventoryWarning ? AppColors.neonOrange : AppColors.neonGreen,
      ));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('فشل التسجيل — تحقق من البيانات', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.neonOrange;
    return ListView(padding: const EdgeInsets.all(16), children: [
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(textDirection: TextDirection.rtl, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inbox_outlined, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Text('تسجيل إنتاج الأغطية', style: AppText.h3),
          ]),
          const SizedBox(height: 16),

          if (widget.machines.isNotEmpty) ...[
            _lbl('الماكينة'),
            _drop(color),
            const SizedBox(height: 14),
          ],

          _lbl('بيانات الإنتاج'),
          Row(textDirection: TextDirection.rtl, children: [
            Expanded(child: _f(_cartonsCtrl, 'عدد الكراتين', color)),
            const SizedBox(width: 10),
            Expanded(child: _f(_capsCtrl, 'أغطية/كرتونة', color)),
          ]),
          const SizedBox(height: 14),

          _totalBox(color),
          const SizedBox(height: 14),

          _lbl('المواد الخام المستخدمة'),
          Row(textDirection: TextDirection.rtl, children: [
            Expanded(child: _f(_hdpeCtrl, 'راتنج HDPE (كغ)', color)),
            const SizedBox(width: 10),
            Expanded(child: _f(_ldpeCtrl, 'راتنج LDPE (كغ)', color)),
          ]),
          const SizedBox(height: 10),
          Row(textDirection: TextDirection.rtl, children: [
            Expanded(child: _f(_colorCtrl, 'ماستر باتش (كغ)', color)),
            const SizedBox(width: 10),
            Expanded(child: _f(_adhesiveCtrl, 'لاصق (كغ)', color)),
          ]),
          const SizedBox(height: 10),
          _f(_cartonsUsedCtrl, 'عدد الكراتين المستخدمة', color),
          const SizedBox(height: 14),

          _f(_notesCtrl, 'ملاحظات (اختياري)', AppColors.textSecondary,
              type: TextInputType.text),
          const SizedBox(height: 14),

          _photoSection(color),
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
                  : const Text('تسجيل إنتاج الأغطية',
                      style: TextStyle(fontFamily: 'Cairo',
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _totalBox(Color color) => Container(
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
            '${_cartonsCtrl.text.isEmpty ? "0" : _cartonsCtrl.text} × '
            '${_capsCtrl.text.isEmpty ? "0" : _capsCtrl.text}',
            style: AppText.label.copyWith(color: AppColors.textSecondary),
            textDirection: TextDirection.rtl,
          ),
        ]),
        Text('$_total', style: AppText.h1.copyWith(color: color, fontSize: 30)),
      ],
    ),
  );

  Widget _photoSection(Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl('صورة شاشة الماكينة'),
      const SizedBox(height: 4),
      Row(textDirection: TextDirection.rtl, children: [
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _photo != null ? c : c.withValues(alpha: 0.3),
                  width: _photo != null ? 2 : 1),
            ),
            child: _photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(File(_photo!.path), fit: BoxFit.cover),
                  )
                : Icon(Icons.add_a_photo_outlined, color: c, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _photo != null ? _photo!.name : 'لم يتم اختيار صورة',
              style: AppText.label.copyWith(
                  color: _photo != null ? AppColors.textPrimary : AppColors.textSecondary),
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _pickPhoto,
              icon: Icon(Icons.photo_camera_outlined, color: c, size: 16),
              label: Text(_photo != null ? 'تغيير الصورة' : 'إضافة صورة',
                  style: AppText.label.copyWith(color: c),
                  textDirection: TextDirection.rtl),
            ),
          ]),
        ),
      ]),
    ],
  );

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

// ─── Preform Tab ──────────────────────────────────────────────────────────────

class _PreformTab extends StatefulWidget {
  final String? shiftId;
  final List<dynamic> machines;
  final int? Function(String keyword) findMaterialId;

  const _PreformTab({
    super.key,
    required this.shiftId,
    required this.machines,
    required this.findMaterialId,
  });

  @override
  State<_PreformTab> createState() => _PreformTabState();
}

class _PreformTabState extends State<_PreformTab> {
  final _moldsCtrl    = TextEditingController();
  final _cavitiesCtrl = TextEditingController();
  final _cyclesCtrl   = TextEditingController();
  final _petCtrl      = TextEditingController();
  final _colorCtrl    = TextEditingController();
  final _notesCtrl    = TextEditingController();

  String? _machineId;
  XFile? _photo;
  bool _submitting = false;

  int get _total {
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
    for (final c in [_moldsCtrl, _cavitiesCtrl, _cyclesCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_moldsCtrl, _cavitiesCtrl, _cyclesCtrl, _petCtrl, _colorCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<ImageSource?> _showPhotoSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.neonCyan),
              title: Text('الكاميرا', style: AppText.body),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.neonPurple),
              title: Text('معرض الصور', style: AppText.body),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await _showPhotoSourceDialog();
    if (source == null) return;
    final img = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
    if (img != null && mounted) setState(() => _photo = img);
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (widget.shiftId == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('اختر الشفت أولاً', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
      return;
    }
    final molds    = int.tryParse(_moldsCtrl.text) ?? 0;
    final cavities = int.tryParse(_cavitiesCtrl.text) ?? 0;
    final cycles   = int.tryParse(_cyclesCtrl.text) ?? 0;
    if (molds == 0 || cavities == 0 || cycles == 0) {
      messenger.showSnackBar(const SnackBar(
        content: Text('أدخل عدد القوالب والتجاويف والدورات', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      final pet      = double.tryParse(_petCtrl.text) ?? 0.0;
      final color    = double.tryParse(_colorCtrl.text) ?? 0.0;
      final shiftId  = int.parse(widget.shiftId!);
      final hourSlot = '${DateTime.now().hour.toString().padLeft(2, '0')}:00';
      final boxesJson = jsonEncode([{'cavities': cavities, 'cycles': cycles, 'numberOfBoxes': molds}]);

      if (_photo != null) {
        final form = FormData.fromMap({
          'shiftId'    : shiftId,
          'hourSlot'   : hourSlot,
          'rawPetUsed' : pet,
          'colorUsed'  : color,
          'totalPieces': _total,
          'boxes'      : boxesJson,
          'notes'      : _notesCtrl.text.trim(),
          if (_machineId != null) 'machineId': int.parse(_machineId!),
          'document'   : await MultipartFile.fromFile(_photo!.path, filename: _photo!.name),
        });
        await ApiService.postMultipart('/production', form);
      } else {
        await ApiService.post('/production', data: {
          'shiftId'    : shiftId,
          'hourSlot'   : hourSlot,
          'rawPetUsed' : pet,
          'colorUsed'  : color,
          'totalPieces': _total,
          'boxes'      : [{'cavities': cavities, 'cycles': cycles, 'numberOfBoxes': molds}],
          'notes'      : _notesCtrl.text.trim(),
          if (_machineId != null) 'machineId': int.parse(_machineId!),
        });
      }

      final deductions = <Future>[];
      void deduct(String keyword, double qty) {
        if (qty <= 0) return;
        final id = widget.findMaterialId(keyword);
        if (id == null) return;
        deductions.add(ApiService.post('/inventory/transactions', data: {
          'materialId'   : id,
          'type'         : 'OUT',
          'quantity'     : qty,
          'referenceType': 'PRODUCTION',
        }));
      }
      deduct('PET', pet);
      deduct('ماستر', color);

      bool inventoryWarning = false;
      if (deductions.isNotEmpty) {
        try {
          await Future.wait(deductions);
        } catch (_) {
          inventoryWarning = true;
        }
      }

      if (!mounted) return;
      for (final c in [_moldsCtrl, _cavitiesCtrl, _cyclesCtrl, _petCtrl, _colorCtrl, _notesCtrl]) {
        c.clear();
      }
      setState(() => _photo = null);
      messenger.showSnackBar(SnackBar(
        content: Text(
          inventoryWarning
              ? 'تم تسجيل الإنتاج ✓ — تحذير: فشل خصم المخزون'
              : 'تم تسجيل الإنتاج بنجاح ✓',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: inventoryWarning ? AppColors.neonOrange : AppColors.neonGreen,
      ));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('فشل التسجيل — تحقق من البيانات', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.neonCyan;
    return ListView(padding: const EdgeInsets.all(16), children: [
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(textDirection: TextDirection.rtl, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings_outlined, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Text('تسجيل إنتاج المخال', style: AppText.h3),
          ]),
          const SizedBox(height: 16),

          if (widget.machines.isNotEmpty) ...[
            _lbl('الماكينة'),
            _drop(color),
            const SizedBox(height: 14),
          ],

          _lbl('بيانات الإنتاج'),
          _f(_moldsCtrl, 'عدد القوالب/الصناديق', color),
          const SizedBox(height: 10),
          Row(textDirection: TextDirection.rtl, children: [
            Expanded(child: _f(_cavitiesCtrl, 'التجاويف', color)),
            const SizedBox(width: 10),
            Expanded(child: _f(_cyclesCtrl, 'الدورات', color)),
          ]),
          const SizedBox(height: 14),

          _totalBox(color),
          const SizedBox(height: 14),

          _lbl('المواد الخام المستخدمة'),
          Row(textDirection: TextDirection.rtl, children: [
            Expanded(child: _f(_petCtrl, 'راتنج PET (كغ)', color)),
            const SizedBox(width: 10),
            Expanded(child: _f(_colorCtrl, 'ماستر باتش (كغ)', color)),
          ]),
          const SizedBox(height: 14),

          _f(_notesCtrl, 'ملاحظات (اختياري)', AppColors.textSecondary,
              type: TextInputType.text),
          const SizedBox(height: 14),

          _photoSection(color),
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
                  : const Text('تسجيل إنتاج المخال',
                      style: TextStyle(fontFamily: 'Cairo',
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _totalBox(Color color) => Container(
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
            '${_moldsCtrl.text.isEmpty ? "0" : _moldsCtrl.text} × '
            '${_cavitiesCtrl.text.isEmpty ? "0" : _cavitiesCtrl.text} × '
            '${_cyclesCtrl.text.isEmpty ? "0" : _cyclesCtrl.text}',
            style: AppText.label.copyWith(color: AppColors.textSecondary),
            textDirection: TextDirection.rtl,
          ),
        ]),
        Text('$_total', style: AppText.h1.copyWith(color: color, fontSize: 30)),
      ],
    ),
  );

  Widget _photoSection(Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl('صورة شاشة الماكينة'),
      const SizedBox(height: 4),
      Row(textDirection: TextDirection.rtl, children: [
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _photo != null ? c : c.withValues(alpha: 0.3),
                  width: _photo != null ? 2 : 1),
            ),
            child: _photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(File(_photo!.path), fit: BoxFit.cover),
                  )
                : Icon(Icons.add_a_photo_outlined, color: c, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _photo != null ? _photo!.name : 'لم يتم اختيار صورة',
              style: AppText.label.copyWith(
                  color: _photo != null ? AppColors.textPrimary : AppColors.textSecondary),
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _pickPhoto,
              icon: Icon(Icons.photo_camera_outlined, color: c, size: 16),
              label: Text(_photo != null ? 'تغيير الصورة' : 'إضافة صورة',
                  style: AppText.label.copyWith(color: c),
                  textDirection: TextDirection.rtl),
            ),
          ]),
        ),
      ]),
    ],
  );

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
