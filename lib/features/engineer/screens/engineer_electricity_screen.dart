import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';

class EngineerElectricityScreen extends StatefulWidget {
  const EngineerElectricityScreen({super.key});
  @override
  State<EngineerElectricityScreen> createState() => _EngineerElectricityScreenState();
}

class _EngineerElectricityScreenState extends State<EngineerElectricityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _shifts   = [];
  List<dynamic> _readings = [];
  double? _kwhPrice;
  bool _loading = true;
  String? _shiftId;

  Map<String, dynamic>? _report;
  bool _loadingReport = false;
  DateTime _reportStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _reportEnd   = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/shifts'),
        ApiService.get('/electricity/readings'),
        ApiService.get('/electricity/kwh-price'),
      ]);

      final shiftRaw   = results[0].data;
      final readingRaw = results[1].data;
      final priceRaw   = results[2].data;

      final shifts   = shiftRaw   is List ? shiftRaw   : (shiftRaw['shifts']     ?? shiftRaw['data']   ?? []);
      final readings = readingRaw is List ? readingRaw : (readingRaw['readings'] ?? readingRaw['data'] ?? []);

      final hour = DateTime.now().hour;
      String? autoId;
      for (final s in shifts) {
        final name = s['name'] as String? ?? '';
        if (name == 'A' && hour >= 0 && hour < 8)   { autoId = s['id'].toString(); break; }
        if (name == 'B' && hour >= 8 && hour < 16) { autoId = s['id'].toString(); break; }
        if (name == 'C' && hour >= 16)              { autoId = s['id'].toString(); break; }
      }

      if (!mounted) return;
      setState(() {
        _shifts   = shifts;
        _readings = readings;
        _kwhPrice = (priceRaw?['price'] as num?)?.toDouble();
        _shiftId  = autoId ?? (shifts.isNotEmpty ? shifts[0]['id'].toString() : null);
        _loading  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadReport() async {
    setState(() => _loadingReport = true);
    try {
      final start = _reportStart.toIso8601String().substring(0, 10);
      final end   = _reportEnd.toIso8601String().substring(0, 10);
      final res = await ApiService.get('/electricity/report?startDate=$start&endDate=$end');
      setState(() { _report = res.data as Map<String, dynamic>?; _loadingReport = false; });
    } catch (_) { setState(() => _loadingReport = false); }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _reportStart : _reportEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { if (isStart) _reportStart = picked; else _reportEnd = picked; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        AiAppBar(
          title: 'الكهرباء',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: _load,
            ),
          ],
        ),
        Container(
          color: AppColors.bgCard,
          child: TabBar(
            controller: _tab,
            indicatorColor: AppColors.neonGold,
            labelColor: AppColors.neonGold,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.edit_outlined),      text: 'التسجيل'),
              Tab(icon: Icon(Icons.history),             text: 'السجل'),
              Tab(icon: Icon(Icons.assessment_outlined), text: 'التقرير'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : TabBarView(
                  controller: _tab,
                  children: [_buildRegistration(), _buildReadings(), _buildReport()],
                ),
        ),
      ]),
    );
  }

  Widget _buildRegistration() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      if (_kwhPrice != null) _InfoBar(price: _kwhPrice!),
      const SizedBox(height: 16),
      _shiftBar(),
      const SizedBox(height: 20),
      _ElectricityForm(
        machineName: 'ماكينة الأغطية',
        machineIcon: Icons.inbox_outlined,
        color: AppColors.neonOrange,
        shiftId: _shiftId,
        onSubmit: _load,
      ),
      const SizedBox(height: 16),
      _ElectricityForm(
        machineName: 'ماكينة المخال',
        machineIcon: Icons.science_outlined,
        color: AppColors.neonCyan,
        shiftId: _shiftId,
        onSubmit: _load,
      ),
    ]),
  );

  Widget _buildReadings() {
    if (_readings.isEmpty) {
      return const Center(child: Text('لا توجد قراءات',
          textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _readings.map((r) => _ReadingCard(reading: r)).toList(),
      ),
    );
  }

  Widget _buildReport() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('نطاق التقرير', style: AppText.h3, textDirection: TextDirection.rtl),
          const SizedBox(height: 12),
          Row(textDirection: TextDirection.rtl, children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_reportStart.toIso8601String().substring(0, 10),
                    style: AppText.body),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonGold,
                    side: const BorderSide(color: AppColors.neonGold)),
              ),
            ),
            const SizedBox(width: 8),
            Text('إلى', style: AppText.caption),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_reportEnd.toIso8601String().substring(0, 10),
                    style: AppText.body),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonGold,
                    side: const BorderSide(color: AppColors.neonGold)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _loadingReport ? null : _loadReport,
              child: _loadingReport
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('عرض التقرير',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            ),
          ),
        ]),
      ),
      if (_report != null) ...[
        const SizedBox(height: 16),
        Row(textDirection: TextDirection.rtl, children: [
          Expanded(child: _statCard('إجمالي الاستهلاك',
              '${_report!['totalConsumption'] ?? 0} كيلوواط', AppColors.neonGold)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('إجمالي التكلفة',
              '${_report!['totalCost'] ?? 0} ج.م', AppColors.neonOrange)),
        ]),
        const SizedBox(height: 10),
        _statCard('عدد القراءات',
            '${_report!['readingsCount'] ?? (_report!['readings'] as List?)?.length ?? 0} قراءة',
            AppColors.neonCyan),
        if (_report!['byMachine'] != null) ...[
          const SizedBox(height: 16),
          Text('التفاصيل حسب الآلة', style: AppText.h3, textDirection: TextDirection.rtl),
          const SizedBox(height: 8),
          ...(_report!['byMachine'] as List).map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(m['name'] ?? '--', style: AppText.body, textDirection: TextDirection.rtl),
                Text('${m['consumption'] ?? 0} kWh — ${m['cost'] ?? 0} ج.م',
                    style: AppText.caption.copyWith(color: AppColors.neonGold),
                    textDirection: TextDirection.rtl),
              ]),
            ),
          )),
        ],
      ],
    ],
  );

  Widget _statCard(String label, String value, Color color) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppText.caption, textDirection: TextDirection.rtl),
      const SizedBox(height: 4),
      Text(value, style: AppText.h3.copyWith(color: color), textDirection: TextDirection.rtl),
    ]),
  );

  Widget _shiftBar() => GlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(textDirection: TextDirection.rtl, children: [
      const Icon(Icons.schedule, color: AppColors.neonPurple, size: 18),
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

// ─── Info Bar ─────────────────────────────────────────────────────────────────

class _InfoBar extends StatelessWidget {
  final double price;
  const _InfoBar({required this.price});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.neonGold.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.3)),
    ),
    child: Row(textDirection: TextDirection.rtl, children: [
      const Icon(Icons.bolt, color: AppColors.neonGold, size: 20),
      const SizedBox(width: 8),
      Text('سعر الكيلوواط: $price ج.م',
          style: AppText.body.copyWith(color: AppColors.neonGold),
          textDirection: TextDirection.rtl),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.neonGold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('السعر الحالي',
            style: AppText.label.copyWith(color: AppColors.neonGold),
            textDirection: TextDirection.rtl),
      ),
    ]),
  );
}

// ─── Electricity Form ─────────────────────────────────────────────────────────

class _ElectricityForm extends StatefulWidget {
  final String machineName;
  final IconData machineIcon;
  final Color color;
  final String? shiftId;
  final VoidCallback onSubmit;

  const _ElectricityForm({
    required this.machineName,
    required this.machineIcon,
    required this.color,
    required this.shiftId,
    required this.onSubmit,
  });

  @override
  State<_ElectricityForm> createState() => _ElectricityFormState();
}

class _ElectricityFormState extends State<_ElectricityForm> {
  final _startCtrl = TextEditingController();
  final _endCtrl   = TextEditingController();
  final _notesCtrl = TextEditingController();
  XFile? _photo;
  bool _submitting = false;

  double get _consumption {
    final s = double.tryParse(_startCtrl.text) ?? 0;
    final e = double.tryParse(_endCtrl.text) ?? 0;
    return e > s ? e - s : 0;
  }

  @override
  void initState() {
    super.initState();
    _startCtrl.addListener(() => setState(() {}));
    _endCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _startCtrl.dispose(); _endCtrl.dispose(); _notesCtrl.dispose();
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

    final start = double.tryParse(_startCtrl.text);
    final end   = double.tryParse(_endCtrl.text);

    if (start == null || end == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('أدخل قراءة البداية والنهاية', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
      return;
    }
    if (end <= start) {
      messenger.showSnackBar(const SnackBar(
        content: Text('قراءة النهاية يجب أن تكون أكبر من البداية', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      final notes = '${widget.machineName} — ${_notesCtrl.text.trim()}';
      if (_photo != null) {
        final form = FormData.fromMap({
          'date'        : DateTime.now().toIso8601String(),
          'shiftId'     : int.parse(widget.shiftId!),
          'startReading': start,
          'endReading'  : end,
          'notes'       : notes,
          'image'       : await MultipartFile.fromFile(_photo!.path, filename: _photo!.name),
        });
        await ApiService.postMultipart('/electricity/readings', form);
      } else {
        await ApiService.post('/electricity/readings', data: {
          'date'        : DateTime.now().toIso8601String(),
          'shiftId'     : int.parse(widget.shiftId!),
          'startReading': start,
          'endReading'  : end,
          'notes'       : notes,
        });
      }

      if (!mounted) return;
      _startCtrl.clear(); _endCtrl.clear(); _notesCtrl.clear();
      setState(() => _photo = null);
      messenger.showSnackBar(const SnackBar(
        content: Text('تم تسجيل القراءة بنجاح ✓', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonGreen,
      ));
      widget.onSubmit();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('فشل التسجيل — تأكد من ضبط سعر الكيلوواط في الإعدادات',
            textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(textDirection: TextDirection.rtl, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.machineIcon, color: c, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.machineName, style: AppText.h3, textDirection: TextDirection.rtl),
              Text('قراءة عداد الكهرباء',
                  style: AppText.caption, textDirection: TextDirection.rtl),
            ]),
          ),
        ]),
        const SizedBox(height: 16),

        Row(textDirection: TextDirection.rtl, children: [
          Expanded(child: _field(_startCtrl, 'قراءة البداية (كيلوواط)', c)),
          const SizedBox(width: 10),
          Expanded(child: _field(_endCtrl,   'قراءة النهاية (كيلوواط)', c)),
        ]),
        const SizedBox(height: 12),

        if (_consumption > 0)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.withValues(alpha: 0.3)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الاستهلاك',
                      style: AppText.caption.copyWith(color: c),
                      textDirection: TextDirection.rtl),
                  Text('قراءة النهاية - البداية',
                      style: AppText.label.copyWith(color: AppColors.textSecondary),
                      textDirection: TextDirection.rtl),
                ]),
                Text('${_consumption.toStringAsFixed(1)} كيلوواط',
                    style: AppText.h3.copyWith(color: c),
                    textDirection: TextDirection.rtl),
              ],
            ),
          ),

        _field(_notesCtrl, 'ملاحظات', AppColors.textSecondary,
            type: TextInputType.text),
        const SizedBox(height: 16),

        _photoSection(c),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.neonGold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(textDirection: TextDirection.rtl, children: [
            const Icon(Icons.info_outline, color: AppColors.neonGold, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'سجّل قراءة البداية عند بدء الشفت، وقراءة النهاية عند انتهائه',
                style: AppText.label.copyWith(color: AppColors.neonGold),
                textDirection: TextDirection.rtl,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: c,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('تسجيل القراءة',
                    style: TextStyle(fontFamily: 'Cairo',
                        fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _photoSection(Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('صورة العداد (اختيارية)',
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
          textDirection: TextDirection.rtl),
      const SizedBox(height: 8),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
      ]),
    ],
  );

  Widget _field(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.number}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: ctrl,
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
}

// ─── Reading Card ──────────────────────────────────────────────────────────────

class _ReadingCard extends StatelessWidget {
  final Map<String, dynamic> reading;
  const _ReadingCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final date        = (reading['date'] ?? reading['createdAt'] ?? '').toString();
    final dateStr     = date.length >= 10 ? date.substring(0, 10) : date;
    final shift       = reading['shift']?['name'] ?? '--';
    final start       = reading['startReading'] ?? 0;
    final end         = reading['endReading'] ?? 0;
    final consumption = reading['consumption'] ?? 0;
    final cost        = reading['shiftCost'] ?? 0;
    final notes       = reading['notes'] as String?;

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
                    color: AppColors.neonGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: AppColors.neonGold, size: 16),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dateStr,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                      textDirection: TextDirection.rtl),
                  Text('شفت $shift',
                      style: AppText.caption, textDirection: TextDirection.rtl),
                ]),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$consumption كيلوواط',
                    style: AppText.h3.copyWith(color: AppColors.neonGold),
                    textDirection: TextDirection.rtl),
                Text('$cost ج.م',
                    style: AppText.caption.copyWith(color: AppColors.neonOrange),
                    textDirection: TextDirection.rtl),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          Row(textDirection: TextDirection.rtl, children: [
            _chip('البداية: $start', AppColors.neonCyan),
            const SizedBox(width: 6),
            _chip('النهاية: $end', AppColors.neonPurple),
          ]),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes, style: AppText.caption, textDirection: TextDirection.rtl),
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
