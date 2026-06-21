import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminElectricityScreen extends StatefulWidget {
  const AdminElectricityScreen({super.key});
  @override
  State<AdminElectricityScreen> createState() => _AdminElectricityScreenState();
}

class _AdminElectricityScreenState extends State<AdminElectricityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<dynamic> _readings = [];
  Map<String, dynamic> _currentPrice = {};
  List<dynamic> _priceHistory = [];
  Map<String, dynamic> _report = {};

  bool _loadingReadings = true;
  bool _loadingPrice = true;
  bool _loadingReport = true;

  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _numFmt = NumberFormat('#,##0.##');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadReadings();
    _loadPrice();
    _loadPriceHistory();
    _loadReport();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadReadings() async {
    setState(() => _loadingReadings = true);
    try {
      final res = await ApiService.get('/electricity/readings');
      final data = res.data;
      setState(() {
        _readings = data is List ? data : (data['readings'] ?? data['data'] ?? []);
        _loadingReadings = false;
      });
    } catch (_) {
      setState(() => _loadingReadings = false);
    }
  }

  Future<void> _loadPrice() async {
    setState(() => _loadingPrice = true);
    try {
      final res = await ApiService.get('/electricity/kwh-price');
      setState(() {
        _currentPrice = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : {};
        _loadingPrice = false;
      });
    } catch (_) {
      setState(() => _loadingPrice = false);
    }
  }

  Future<void> _loadPriceHistory() async {
    try {
      final res = await ApiService.get('/electricity/kwh-price/history');
      final data = res.data;
      setState(() {
        _priceHistory = data is List ? data : (data['history'] ?? data['data'] ?? []);
      });
    } catch (_) {}
  }

  Future<void> _loadReport() async {
    setState(() => _loadingReport = true);
    try {
      final res = await ApiService.get('/electricity/report');
      setState(() {
        _report = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : {};
        _loadingReport = false;
      });
    } catch (_) {
      setState(() => _loadingReport = false);
    }
  }

  String _numFormat(dynamic val) {
    if (val == null) return '--';
    try {
      final n = val is num ? val : num.parse('$val');
      return _numFmt.format(n);
    } catch (_) {
      return '$val';
    }
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return '--';
    try {
      return _dateFmt.format(DateTime.parse('$iso').toLocal());
    } catch (_) {
      return '$iso';
    }
  }

  Widget _inputField(TextEditingController ctrl, String hint, {TextInputType? keyboard}) {
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
        keyboardType: keyboard,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: AppText.label.copyWith(color: AppColors.textSecondary));
  }

  void _showEditReadingSheet(Map<String, dynamic> reading) {
    final notesCtrl = TextEditingController(text: (reading['notes'] ?? '') as String);
    final startCtrl = TextEditingController(text: reading['startReading']?.toString() ?? '');
    final endCtrl = TextEditingController(text: reading['endReading']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              right: 24,
              left: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تعديل القراءة', style: AppText.h2),
                const SizedBox(height: 16),
                _fieldLabel('قراءة البداية (كيلوواط)'),
                const SizedBox(height: 6),
                _inputField(startCtrl, 'قراءة البداية', keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _fieldLabel('قراءة النهاية (كيلوواط)'),
                const SizedBox(height: 6),
                _inputField(endCtrl, 'قراءة النهاية', keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _fieldLabel('ملاحظات'),
                const SizedBox(height: 6),
                _inputField(notesCtrl, 'ملاحظات اختيارية'),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final payload = <String, dynamic>{};
                    final startTxt = startCtrl.text.trim();
                    final endTxt = endCtrl.text.trim();
                    final notesTxt = notesCtrl.text.trim();
                    if (startTxt.isNotEmpty) payload['startReading'] = double.tryParse(startTxt);
                    if (endTxt.isNotEmpty) payload['endReading'] = double.tryParse(endTxt);
                    if (notesTxt.isNotEmpty) payload['notes'] = notesTxt;
                    try {
                      await ApiService.patch(
                          '/electricity/readings/${reading['id']}',
                          data: payload);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadReadings();
                    } catch (_) {}
                  },
                  child: const Text('حفظ',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteReading(dynamic id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: Text('حذف القراءة', style: AppText.h3),
            content: Text('هل أنت متأكد من حذف هذه القراءة؟', style: AppText.body),
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
                    await ApiService.delete('/electricity/readings/$id');
                    _loadReadings();
                  } catch (_) {}
                },
                child: Text('حذف',
                    style: AppText.body.copyWith(color: AppColors.neonRed)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdatePriceDialog() {
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: Text('تحديث سعر الكيلوواط', style: AppText.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fieldLabel('السعر الجديد (جنيه / كيلوواط)'),
                const SizedBox(height: 6),
                _inputField(priceCtrl, 'مثال: 1.50', keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _fieldLabel('ملاحظات'),
                const SizedBox(height: 6),
                _inputField(notesCtrl, 'ملاحظات اختيارية'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء',
                    style: AppText.body.copyWith(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () async {
                  final price = double.tryParse(priceCtrl.text.trim());
                  if (price == null) return;
                  final notesTxt = notesCtrl.text.trim();
                  final body = <String, dynamic>{'price': price};
                  if (notesTxt.isNotEmpty) body['notes'] = notesTxt;
                  try {
                    await ApiService.post('/electricity/kwh-price', data: body);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadPrice();
                    _loadPriceHistory();
                  } catch (_) {}
                },
                child: Text('تحديث',
                    style: AppText.body.copyWith(color: AppColors.neonGold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(
          children: [
            AiAppBar(title: 'إدارة الكهرباء'),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildReadingsTab(),
                  _buildPriceTab(),
                  _buildReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            color: AppColors.neonGold.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: AppText.label.copyWith(color: AppColors.textPrimary),
          unselectedLabelStyle: AppText.label.copyWith(color: AppColors.textSecondary),
          tabs: const [
            Tab(text: 'القراءات'),
            Tab(text: 'سعر الكيلوواط'),
            Tab(text: 'تقرير الكهرباء'),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsTab() {
    if (_loadingReadings) return const LoadingWidget();
    if (_readings.isEmpty) {
      return const EmptyStateWidget(
          message: 'لا توجد قراءات', icon: Icons.electric_meter_outlined);
    }

    double totalConsumption = 0;
    double totalCost = 0;
    for (final r in _readings) {
      final c = r['consumption'] ?? r['consumptionKwh'];
      final co = r['cost'] ?? r['costEgp'];
      if (c != null) totalConsumption += (c is num ? c.toDouble() : double.tryParse('$c') ?? 0);
      if (co != null) totalCost += (co is num ? co.toDouble() : double.tryParse('$co') ?? 0);
    }

    return RefreshIndicator(
      onRefresh: _loadReadings,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('إجمالي الاستهلاك',
                              style: AppText.caption
                                  .copyWith(color: AppColors.textSecondary)),
                          Text('${_numFormat(totalConsumption)} كيلوواط',
                              style: AppText.h3.copyWith(color: AppColors.neonGold)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.border),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('إجمالي التكلفة',
                              style: AppText.caption
                                  .copyWith(color: AppColors.textSecondary)),
                          Text('${_numFormat(totalCost)} ج',
                              style: AppText.h3.copyWith(color: AppColors.neonGreen)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildReadingCard(_readings[i]),
                childCount: _readings.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(dynamic r) {
    final shift = r['shift'];
    final user = r['user'] ?? r['recorder'];
    final shiftName =
        (shift is Map ? shift['name'] : null) ?? r['shiftName'] ?? '--';
    final userName =
        (user is Map ? user['name'] : null) ?? r['recorderName'] ?? '--';
    final date = r['date'] ?? r['createdAt'];
    final start = r['startReading'];
    final end = r['endReading'];
    final consumption = r['consumption'] ?? r['consumptionKwh'];
    final cost = r['cost'] ?? r['costEgp'];
    final notes = r['notes'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                    color: AppColors.neonGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.electric_meter_outlined,
                      color: AppColors.neonGold, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(shiftName,
                          style: AppText.h3,
                          textDirection: TextDirection.rtl),
                      Text(
                        '$userName  •  ${_fmtDate(date)}',
                        style: AppText.caption
                            .copyWith(color: AppColors.textSecondary),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.neonCyan, size: 20),
                      onPressed: () =>
                          _showEditReadingSheet(Map<String, dynamic>.from(r as Map)),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.neonRed, size: 20),
                      onPressed: () => _confirmDeleteReading(r['id']),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _readingCell('بداية', _numFormat(start), AppColors.textSecondary),
                _readingCell('نهاية', _numFormat(end), AppColors.textSecondary),
                _readingCell('استهلاك', '${_numFormat(consumption)} ك', AppColors.neonGold),
                _readingCell('تكلفة', '${_numFormat(cost)} ج', AppColors.neonGreen),
              ],
            ),
            if (notes != null && '$notes'.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('$notes',
                  style: AppText.caption.copyWith(color: AppColors.textSecondary),
                  textDirection: TextDirection.rtl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _readingCell(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: AppText.caption.copyWith(
                color: AppColors.textSecondary, fontSize: 10)),
        Text(value, style: AppText.label.copyWith(color: color)),
      ],
    );
  }

  Widget _buildPriceTab() {
    if (_loadingPrice) return const LoadingWidget();
    return RefreshIndicator(
      onRefresh: () async {
        await _loadPrice();
        await _loadPriceHistory();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('السعر الحالي', style: AppText.h2),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGold,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: _showUpdatePriceDialog,
                      icon: const Icon(Icons.update, color: Colors.white, size: 16),
                      label: const Text('تحديث السعر',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neonGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bolt, color: AppColors.neonGold, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_numFormat(_currentPrice['price'])} جنيه / كيلوواط',
                            style: AppText.h1.copyWith(color: AppColors.neonGold),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            'سارٍ من: ${_fmtDate(_currentPrice['effectiveFrom'])}',
                            style: AppText.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_currentPrice['notes'] != null &&
                    '${_currentPrice['notes']}'.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${_currentPrice['notes']}',
                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_priceHistory.isNotEmpty) ...[
            Text('سجل تغييرات السعر', style: AppText.h2),
            const SizedBox(height: 12),
            ..._priceHistory.map((h) => _buildPriceHistoryItem(h)),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceHistoryItem(dynamic h) {
    final price = h['price'];
    final date = h['effectiveFrom'] ?? h['createdAt'];
    final notes = h['notes'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neonGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, color: AppColors.neonGold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_numFormat(price)} جنيه / كيلوواط',
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    _fmtDate(date),
                    style: AppText.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  if (notes != null && '$notes'.isNotEmpty)
                    Text(
                      '$notes',
                      style: AppText.caption.copyWith(color: AppColors.textMuted),
                      textDirection: TextDirection.rtl,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTab() {
    if (_loadingReport) return const LoadingWidget();
    if (_report.isEmpty) {
      return const EmptyStateWidget(
          message: 'لا يوجد تقرير متاح', icon: Icons.assessment_outlined);
    }

    final totalConsumption = _report['totalConsumption'];
    final totalCost = _report['totalCost'];
    final avgDaily = _report['avgDaily'] ?? _report['averageDaily'];
    final readingsCount = _report['readingsCount'] ?? _report['count'];
    final shiftsRaw = _report['shifts'] ?? _report['byShift'];
    final shiftsList = shiftsRaw is List ? shiftsRaw : <dynamic>[];

    const knownKeys = {
      'totalConsumption', 'totalCost', 'avgDaily', 'averageDaily',
      'readingsCount', 'count', 'shifts', 'byShift',
    };

    final extraEntries = _report.entries
        .where((e) => !knownKeys.contains(e.key) && e.value != null)
        .toList();

    final kpiWidgets = <Widget>[];
    if (totalConsumption != null) {
      kpiWidgets.add(KpiCard(
        label: 'إجمالي الاستهلاك (ك.و)',
        value: _numFormat(totalConsumption),
        gradient: AppColors.goldGrad,
        icon: Icons.electric_bolt,
      ));
    }
    if (totalCost != null) {
      kpiWidgets.add(KpiCard(
        label: 'إجمالي التكلفة (ج)',
        value: _numFormat(totalCost),
        gradient: AppColors.successGrad,
        icon: Icons.payments_outlined,
      ));
    }
    if (avgDaily != null) {
      kpiWidgets.add(KpiCard(
        label: 'متوسط يومي (ك.و)',
        value: _numFormat(avgDaily),
        gradient: AppColors.primaryGrad,
        icon: Icons.trending_up,
      ));
    }
    if (readingsCount != null) {
      kpiWidgets.add(KpiCard(
        label: 'عدد القراءات',
        value: '$readingsCount',
        gradient: AppColors.warningGrad,
        icon: Icons.electric_meter_outlined,
      ));
    }

    double maxShiftVal = 0;
    for (final s in shiftsList) {
      if (s is! Map) continue;
      final v = s['consumption'] ?? s['totalConsumption'];
      final n = v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
      if (n > maxShiftVal) maxShiftVal = n;
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (kpiWidgets.isNotEmpty) ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: kpiWidgets,
            ),
            const SizedBox(height: 20),
          ],
          if (shiftsList.isNotEmpty) ...[
            Text('توزيع الاستهلاك بالورديات', style: AppText.h2),
            const SizedBox(height: 12),
            ...shiftsList.map((s) => _buildShiftBar(s, maxShiftVal)),
          ],
          ...extraEntries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: AppText.body
                            .copyWith(color: AppColors.textSecondary),
                        textDirection: TextDirection.rtl),
                    Text('${e.value}',
                        style: AppText.body
                            .copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftBar(dynamic s, double maxVal) {
    if (s is! Map) return const SizedBox.shrink();
    final name = s['name'] ?? s['shiftName'] ?? '--';
    final consumption = s['consumption'] ?? s['totalConsumption'];
    final cost = s['cost'] ?? s['totalCost'];
    final val = consumption is num
        ? consumption.toDouble()
        : double.tryParse('$consumption') ?? 0;
    final ratio = maxVal > 0 ? val / maxVal : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$name',
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    textDirection: TextDirection.rtl),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_numFormat(consumption)} ك.و',
                        style: AppText.label.copyWith(color: AppColors.neonGold)),
                    if (cost != null)
                      Text('${_numFormat(cost)} ج',
                          style: AppText.caption.copyWith(color: AppColors.neonGreen)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonGold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
