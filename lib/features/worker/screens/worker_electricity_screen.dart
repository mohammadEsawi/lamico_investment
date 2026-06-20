import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/worker_nav.dart';

class WorkerElectricityScreen extends StatefulWidget {
  const WorkerElectricityScreen({super.key});
  @override
  State<WorkerElectricityScreen> createState() => _WorkerElectricityScreenState();
}

class _WorkerElectricityScreenState extends State<WorkerElectricityScreen> {
  List<dynamic> _shifts   = [];
  List<dynamic> _readings = [];
  double? _kwhPrice;
  bool _loading = true;
  String? _shiftId;

  @override
  void initState() { super.initState(); _load(); }

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
        if (name == 'A' && hour >= 0  && hour < 8)  { autoId = s['id'].toString(); break; }
        if (name == 'B' && hour >= 8  && hour < 16) { autoId = s['id'].toString(); break; }
        if (name == 'C' && hour >= 16)               { autoId = s['id'].toString(); break; }
      }

      setState(() {
        _shifts   = shifts;
        _readings = readings;
        _kwhPrice = (priceRaw?['price'] as num?)?.toDouble();
        _shiftId  = autoId ?? (shifts.isNotEmpty ? shifts[0]['id'].toString() : null);
        _loading  = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const WorkerNav(selectedIndex: 3),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'عدادات الكهرباء'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(padding: const EdgeInsets.all(16), children: [
                      // Info bar
                      if (_kwhPrice != null)
                        _InfoBar(price: _kwhPrice!),
                      const SizedBox(height: 16),

                      // Shift selector
                      _shiftBar(),
                      const SizedBox(height: 20),

                      // Caps machine form
                      _ElectricityForm(
                        machineName: 'ماكينة الأغطية',
                        machineIcon: Icons.inbox_outlined,
                        color: AppColors.neonOrange,
                        shiftId: _shiftId,
                        onSubmit: _load,
                      ),
                      const SizedBox(height: 16),

                      // Preform machine form
                      _ElectricityForm(
                        machineName: 'ماكينة المخال',
                        machineIcon: Icons.science_outlined,
                        color: AppColors.neonCyan,
                        shiftId: _shiftId,
                        onSubmit: _load,
                      ),
                      const SizedBox(height: 24),

                      // History
                      if (_readings.isNotEmpty) ...[
                        Row(textDirection: TextDirection.rtl, children: [
                          const Icon(Icons.history, color: AppColors.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          Text('سجل القراءات', style: AppText.h3),
                        ]),
                        const SizedBox(height: 12),
                        ..._readings.take(20).map((r) => _ReadingCard(reading: r)),
                      ],
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }

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

  Future<void> _submit() async {
    if (widget.shiftId == null) { _snack('اختر الشفت أولاً', err: true); return; }

    final start = double.tryParse(_startCtrl.text);
    final end   = double.tryParse(_endCtrl.text);

    if (start == null || end == null) { _snack('أدخل قراءة البداية والنهاية', err: true); return; }
    if (end <= start) { _snack('قراءة النهاية يجب أن تكون أكبر من البداية', err: true); return; }

    setState(() => _submitting = true);
    try {
      await ApiService.post('/electricity/readings', data: {
        'date'        : DateTime.now().toIso8601String(),
        'shiftId'     : int.parse(widget.shiftId!),
        'startReading': start,
        'endReading'  : end,
        'notes'       : '${widget.machineName} — ${_notesCtrl.text.trim()}',
      });

      _startCtrl.clear(); _endCtrl.clear(); _notesCtrl.clear();
      _snack('تم تسجيل القراءة بنجاح ✓');
      widget.onSubmit();
    } catch (_) {
      _snack('فشل التسجيل — تأكد من ضبط سعر الكيلوواط في الإعدادات', err: true);
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
    final c = widget.color;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
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

        // Readings
        Row(textDirection: TextDirection.rtl, children: [
          Expanded(child: _field(_startCtrl, 'قراءة البداية (كيلوواط)', c)),
          const SizedBox(width: 10),
          Expanded(child: _field(_endCtrl,   'قراءة النهاية (كيلوواط)', c)),
        ]),
        const SizedBox(height: 12),

        // Consumption display
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

        // Reminder note
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
