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

class AdminPerformanceScreen extends StatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  State<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends State<AdminPerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Tab 1 — records
  List<dynamic> _records = [];
  bool _loadingRecords = true;

  // Shared users list
  List<dynamic> _users = [];

  // Tab 2 — manual form controllers
  dynamic _formUserId;
  final _periodCtrl = TextEditingController();
  final _totalDaysCtrl = TextEditingController();
  final _presentCtrl = TextEditingController();
  final _lateCtrl = TextEditingController();
  final _absentCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _overtimeCtrl = TextEditingController();
  final _productionCtrl = TextEditingController();
  final _qualityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  final _numFmt = NumberFormat('#,##0.##');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadRecords();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _periodCtrl.dispose();
    _totalDaysCtrl.dispose();
    _presentCtrl.dispose();
    _lateCtrl.dispose();
    _absentCtrl.dispose();
    _hoursCtrl.dispose();
    _overtimeCtrl.dispose();
    _productionCtrl.dispose();
    _qualityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _loadingRecords = true);
    try {
      final res = await ApiService.get('/performance');
      final data = res.data;
      setState(() {
        _records =
            data is List ? data : (data['items'] ?? data['data'] ?? []);
        _loadingRecords = false;
      });
    } catch (_) {
      setState(() => _loadingRecords = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final res = await ApiService.get('/users/all');
      final data = res.data;
      setState(() {
        _users =
            data is List ? data : (data['users'] ?? data['data'] ?? []);
      });
    } catch (_) {}
  }

  Future<void> _deleteRecord(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('حذف السجل', style: AppText.h3),
          content:
              Text('هل أنت متأكد من حذف هذا السجل؟', style: AppText.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء',
                  style: AppText.body
                      .copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حذف',
                  style:
                      AppText.body.copyWith(color: AppColors.neonRed)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.delete('/performance/$id');
        _loadRecords();
      } catch (_) {}
    }
  }

  void _showCalculateDialog() {
    dynamic calcUserId;
    final calcPeriodCtrl =
        TextEditingController(text: DateFormat('yyyy-MM').format(DateTime.now()));
    bool calculating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: Text('احتساب الأداء', style: AppText.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('الموظف', style: AppText.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                _dropdownWidget(
                  value: calcUserId,
                  items: _users,
                  hint: 'اختر موظفاً',
                  onChanged: (v) => setS(() => calcUserId = v),
                ),
                const SizedBox(height: 14),
                Text('الفترة', style: AppText.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                _inputField(calcPeriodCtrl, 'مثال: 2025-01'),
                const SizedBox(height: 4),
                Text('الصيغة: YYYY-MM',
                    style: AppText.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: calculating ? null : () => Navigator.pop(ctx),
                child: Text('إلغاء',
                    style: AppText.body.copyWith(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: calculating || calcUserId == null
                    ? null
                    : () async {
                        setS(() => calculating = true);
                        try {
                          await ApiService.post('/performance/calculate',
                              data: {
                                'userId': calcUserId,
                                'period': calcPeriodCtrl.text.trim(),
                              });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadRecords();
                        } catch (_) {
                          setS(() => calculating = false);
                        }
                      },
                child: calculating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('احتساب',
                        style: TextStyle(
                            fontFamily: 'Cairo', color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitManual() async {
    if (_formUserId == null || _periodCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiService.post('/performance', data: {
        'userId': _formUserId,
        'period': _periodCtrl.text.trim(),
        'totalWorkingDays': int.tryParse(_totalDaysCtrl.text.trim()) ?? 0,
        'presentDays': int.tryParse(_presentCtrl.text.trim()) ?? 0,
        'lateDays': int.tryParse(_lateCtrl.text.trim()) ?? 0,
        'absentDays': int.tryParse(_absentCtrl.text.trim()) ?? 0,
        'totalHours': double.tryParse(_hoursCtrl.text.trim()) ?? 0,
        'overtimeHours': double.tryParse(_overtimeCtrl.text.trim()) ?? 0,
        'productionCount': int.tryParse(_productionCtrl.text.trim()) ?? 0,
        'qualityScore': double.tryParse(_qualityCtrl.text.trim()) ?? 0,
        'notes': _notesCtrl.text.trim(),
      });
      // Clear form
      setState(() {
        _formUserId = null;
        _submitting = false;
      });
      _periodCtrl.clear();
      _totalDaysCtrl.clear();
      _presentCtrl.clear();
      _lateCtrl.clear();
      _absentCtrl.clear();
      _hoursCtrl.clear();
      _overtimeCtrl.clear();
      _productionCtrl.clear();
      _qualityCtrl.clear();
      _notesCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء سجل الأداء بنجاح')),
        );
        _loadRecords();
      }
    } catch (_) {
      setState(() => _submitting = false);
    }
  }

  Color _scoreColor(dynamic score) {
    final s = score is num ? score.toDouble() : double.tryParse('$score') ?? 0;
    if (s > 80) return AppColors.neonGreen;
    if (s > 60) return AppColors.neonOrange;
    return AppColors.neonRed;
  }

  String _userName(dynamic record) {
    final user = record['user'];
    if (user is Map) return user['fullName'] ?? '--';
    return record['userName'] ?? '--';
  }

  // Shared input field widget
  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) =>
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
          textDirection: TextDirection.rtl,
          keyboardType: keyboardType,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body,
            border: InputBorder.none,
          ),
        ),
      );

  Widget _dropdownWidget({
    required dynamic value,
    required List<dynamic> items,
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
            items: items.map((u) {
              return DropdownMenuItem<dynamic>(
                value: u['id'],
                child: Text(
                  u['fullName'] ?? u['name'] ?? '--',
                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                  textDirection: TextDirection.rtl,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _formLabel(String text) =>
      Text(text, style: AppText.label.copyWith(color: AppColors.textSecondary));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 4),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.neonGreen,
              onPressed: _showCalculateDialog,
              tooltip: 'احتساب الأداء',
              child: const Icon(Icons.calculate_outlined, color: Colors.white),
            )
          : null,
      body: AiBackground(
        child: Column(
          children: [
            AiAppBar(title: 'الأداء الوظيفي'),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildRecordsTab(),
                  _buildManualTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabs,
            onTap: (_) => setState(() {}),
            indicator: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle:
                AppText.label.copyWith(color: AppColors.textPrimary),
            unselectedLabelStyle:
                AppText.label.copyWith(color: AppColors.textSecondary),
            tabs: const [
              Tab(text: 'السجلات'),
              Tab(text: 'إنشاء يدوي'),
            ],
          ),
        ),
      );

  Widget _buildRecordsTab() {
    if (_loadingRecords) return const LoadingWidget();
    if (_records.isEmpty) {
      return const EmptyStateWidget(
        message: 'لا توجد سجلات أداء',
        icon: Icons.assessment_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final rec = _records[i];
          final name = _userName(rec);
          final period = rec['period'] ?? '--';
          final score = rec['performanceScore'];
          final scoreVal = score is num
              ? score.toDouble()
              : double.tryParse('$score') ?? 0;
          final scoreColor = _scoreColor(score);
          final presentDays = rec['presentDays'] ?? 0;
          final totalDays = rec['totalWorkingDays'] ?? 0;
          final netBonus = rec['netBonus'];
          final netBonusVal = netBonus is num
              ? netBonus.toDouble()
              : double.tryParse('$netBonus') ?? 0;

          return GestureDetector(
            onLongPress: () => _deleteRecord(rec['id']),
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
                          color: scoreColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.bar_chart_outlined,
                            color: scoreColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(name,
                                style: AppText.h3,
                                textDirection: TextDirection.rtl),
                            Text('الفترة: $period',
                                style: AppText.caption.copyWith(
                                    color: AppColors.textSecondary),
                                textDirection: TextDirection.rtl),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${scoreVal.toStringAsFixed(1)}%',
                          style: AppText.h3.copyWith(color: scoreColor),
                        ),
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
                      _infoChip(Icons.calendar_today_outlined,
                          '$presentDays / $totalDays يوم', AppColors.neonCyan),
                      _infoChip(
                        netBonusVal >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        'صافي المكافأة: ${_numFmt.format(netBonusVal)}',
                        netBonusVal >= 0
                            ? AppColors.neonGreen
                            : AppColors.neonRed,
                      ),
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

  Widget _infoChip(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: AppText.caption.copyWith(color: color)),
        ],
      );

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إنشاء سجل أداء يدوي', style: AppText.h3),
              const SizedBox(height: 18),

              _formLabel('الموظف *'),
              const SizedBox(height: 6),
              _dropdownWidget(
                value: _formUserId,
                items: _users,
                hint: 'اختر موظفاً',
                onChanged: (v) => setState(() => _formUserId = v),
              ),
              const SizedBox(height: 14),

              _formLabel('الفترة * (مثال: 2025-01)'),
              const SizedBox(height: 6),
              _inputField(_periodCtrl, '2025-01'),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _formLabel('إجمالي أيام العمل'),
                        const SizedBox(height: 6),
                        _inputField(_totalDaysCtrl, '26',
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _formLabel('أيام الحضور'),
                        const SizedBox(height: 6),
                        _inputField(_presentCtrl, '24',
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _formLabel('أيام التأخير'),
                        const SizedBox(height: 6),
                        _inputField(_lateCtrl, '2',
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _formLabel('أيام الغياب'),
                        const SizedBox(height: 6),
                        _inputField(_absentCtrl, '0',
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _formLabel('إجمالي الساعات'),
                        const SizedBox(height: 6),
                        _inputField(_hoursCtrl, '192',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _formLabel('ساعات إضافية'),
                        const SizedBox(height: 6),
                        _inputField(_overtimeCtrl, '8',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _formLabel('عدد الإنتاج'),
                        const SizedBox(height: 6),
                        _inputField(_productionCtrl, '150',
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _formLabel('درجة الجودة (0-100)'),
                        const SizedBox(height: 6),
                        _inputField(_qualityCtrl, '85',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _formLabel('ملاحظات'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: TextField(
                  controller: _notesCtrl,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'ملاحظات اختيارية...',
                    hintStyle: AppText.body,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitting ? null : _submitManual,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'إنشاء السجل',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
