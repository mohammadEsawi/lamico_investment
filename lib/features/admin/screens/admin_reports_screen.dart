import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _formatMonth(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

String _displayDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        bottomNavigationBar: const AdminNav(selectedIndex: 0),
        body: AiBackground(
          child: Column(
            children: [
              AiAppBar(title: 'التقارير'),
              _TabBar(),
              Expanded(
                child: TabBarView(
                  children: [
                    _ProductionTab(),
                    _InventoryTab(),
                    _AttendanceTab(),
                    _PayrollTab(),
                    _SalesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.bgCard,
      child: const TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.neonPurple,
        labelColor: AppColors.neonPurple,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppText.h3,
        unselectedLabelStyle: AppText.body,
        tabs: [
          Tab(text: 'الإنتاج'),
          Tab(text: 'المخزون'),
          Tab(text: 'الحضور'),
          Tab(text: 'الرواتب'),
          Tab(text: 'المبيعات'),
        ],
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onFetch;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final bool loading;

  const _DateRangeSelector({
    required this.startDate,
    required this.endDate,
    required this.onFetch,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.loading,
  });

  Future<void> _pickDate(BuildContext context, DateTime initial, ValueChanged<DateTime> onChanged) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          GestureDetector(
            onTap: () => _pickDate(context, startDate, onStartChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
              ),
              child: Text(
                'من: ${_displayDate(startDate)}',
                style: AppText.caption.copyWith(color: AppColors.neonPurple),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _pickDate(context, endDate, onEndChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
              ),
              child: Text(
                'إلى: ${_displayDate(endDate)}',
                style: AppText.caption.copyWith(color: AppColors.neonBlue),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const Spacer(),
          loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.neonPurple,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.search, color: AppColors.neonPurple),
                  onPressed: onFetch,
                  tooltip: 'جلب البيانات',
                ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onFetch;
  final bool loading;

  const _MonthSelector({
    required this.month,
    required this.onChanged,
    required this.onFetch,
    required this.loading,
  });

  Future<void> _pickMonth(BuildContext context) async {
    DateTime selected = month;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('اختر الشهر', style: AppText.h3, textDirection: TextDirection.rtl),
        content: SizedBox(
          width: 300,
          height: 300,
          child: _MonthPicker(initial: selected, onChanged: (d) { selected = d; }),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); onChanged(selected); },
            child: const Text('تأكيد', style: TextStyle(color: AppColors.neonPurple, fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          GestureDetector(
            onTap: () => _pickMonth(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  const Icon(Icons.calendar_month_outlined, color: AppColors.neonPurple, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatMonth(month),
                    style: AppText.body.copyWith(color: AppColors.neonPurple),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.neonPurple,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.neonPurple),
                  onPressed: onFetch,
                ),
        ],
      ),
    );
  }
}

class _MonthPicker extends StatefulWidget {
  final DateTime initial;
  final ValueChanged<DateTime> onChanged;

  const _MonthPicker({required this.initial, required this.onChanged});

  @override
  State<_MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<_MonthPicker> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return Column(
      children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.neonPurple),
              onPressed: () => setState(() { _year--; widget.onChanged(DateTime(_year, _month)); }),
            ),
            Text('$_year', style: AppText.h3),
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.neonPurple),
              onPressed: () => setState(() { _year++; widget.onChanged(DateTime(_year, _month)); }),
            ),
          ],
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final selected = i + 1 == _month;
              return GestureDetector(
                onTap: () => setState(() {
                  _month = i + 1;
                  widget.onChanged(DateTime(_year, _month));
                }),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.neonPurple.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppColors.neonPurple
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    months[i],
                    style: AppText.caption.copyWith(
                      color: selected ? AppColors.neonPurple : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DataCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DataCard({required this.data});

  String _arabicKey(String key) {
    const map = {
      'total': 'الإجمالي',
      'count': 'العدد',
      'date': 'التاريخ',
      'name': 'الاسم',
      'quantity': 'الكمية',
      'amount': 'المبلغ',
      'pieces': 'القطع',
      'cartons': 'الكراتين',
      'machine': 'الآلة',
      'type': 'النوع',
      'status': 'الحالة',
      'present': 'حاضر',
      'absent': 'غائب',
      'late': 'متأخر',
      'overtime': 'إضافي',
      'employees': 'الموظفون',
      'salary': 'الراتب',
      'average': 'المتوسط',
      'revenue': 'الإيرادات',
      'customers': 'العملاء',
      'invoices': 'الفواتير',
      'products': 'المنتجات',
      'role': 'الدور',
      'totalPieces': 'إجمالي القطع',
      'totalCartons': 'إجمالي الكراتين',
      'machinesBreakdown': 'تفاصيل الآلات',
      'totalPayroll': 'إجمالي الرواتب',
      'employeeCount': 'عدد الموظفين',
      'averageSalary': 'متوسط الراتب',
      'totalRevenue': 'إجمالي الإيرادات',
      'customerCount': 'عدد العملاء',
      'invoiceCount': 'عدد الفواتير',
      'topProducts': 'أفضل المنتجات',
      'totalPresent': 'إجمالي الحضور',
      'totalAbsent': 'إجمالي الغياب',
      'totalLate': 'إجمالي التأخر',
      'totalOvertime': 'إجمالي الساعات الإضافية',
      'in': 'وارد',
      'out': 'صادر',
      'material': 'المادة',
      'currentQty': 'الكمية الحالية',
      'unit': 'الوحدة',
    };
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map((e) {
          final val = e.value;
          if (val is Map) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _arabicKey(e.key),
                    style: AppText.label.copyWith(color: AppColors.neonPurple),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  _DataCard(data: Map<String, dynamic>.from(val)),
                ],
              ),
            );
          }
          if (val is List) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _arabicKey(e.key),
                    style: AppText.label.copyWith(color: AppColors.neonPurple),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  ...val.map((item) => item is Map
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 6, right: 8),
                          child: _DataCard(data: Map<String, dynamic>.from(item)),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 2),
                          child: Text(
                            '• ${item.toString()}',
                            style: AppText.body,
                            textDirection: TextDirection.rtl,
                          ),
                        )),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  '${_arabicKey(e.key)}:',
                  style: AppText.caption.copyWith(color: AppColors.textSecondary),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    val?.toString() ?? '--',
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

Widget _buildResponseView(dynamic data, {String emptyMessage = 'لا توجد بيانات للفترة المحددة'}) {
  if (data == null) {
    return Center(
      child: Text(emptyMessage, style: AppText.body, textDirection: TextDirection.rtl),
    );
  }
  if (data is Map && data.isEmpty) {
    return Center(
      child: Text(emptyMessage, style: AppText.body, textDirection: TextDirection.rtl),
    );
  }
  if (data is List && data.isEmpty) {
    return Center(
      child: Text(emptyMessage, style: AppText.body, textDirection: TextDirection.rtl),
    );
  }
  if (data is Map) {
    return _DataCard(data: Map<String, dynamic>.from(data));
  }
  if (data is List) {
    return Column(
      children: data.map((item) {
        if (item is Map) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DataCard(data: Map<String, dynamic>.from(item)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GlassCard(
            child: Text(item.toString(), style: AppText.body, textDirection: TextDirection.rtl),
          ),
        );
      }).toList(),
    );
  }
  return GlassCard(
    child: Text(data.toString(), style: AppText.body, textDirection: TextDirection.rtl),
  );
}

Widget _buildErrorWidget(String message, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: AppColors.neonRed, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          style: AppText.body.copyWith(color: AppColors.neonRed),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;

  const _SectionHeader({required this.title, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppText.h3.copyWith(color: color), textDirection: TextDirection.rtl),
      ],
    );
  }
}

class _ProductionTab extends StatefulWidget {
  @override
  State<_ProductionTab> createState() => _ProductionTabState();
}

class _ProductionTabState extends State<_ProductionTab> {
  DateTime _dailyDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  bool _loadingDaily = false;
  bool _loadingWeekly = false;

  dynamic _dailyData;
  dynamic _weeklyData;
  String? _dailyError;
  String? _weeklyError;

  Future<void> _fetchDaily() async {
    setState(() { _loadingDaily = true; _dailyError = null; });
    try {
      final res = await ApiService.get('/reports/production/daily', params: {
        'date': _formatDate(_dailyDate),
      });
      setState(() { _dailyData = res.data; _loadingDaily = false; });
    } catch (e) {
      setState(() { _dailyError = e.toString(); _loadingDaily = false; });
    }
  }

  Future<void> _fetchWeekly() async {
    setState(() { _loadingWeekly = true; _weeklyError = null; });
    try {
      final res = await ApiService.get('/reports/production/weekly', params: {
        'startDate': _formatDate(_startDate),
        'endDate': _formatDate(_endDate),
      });
      setState(() { _weeklyData = res.data; _loadingWeekly = false; });
    } catch (e) {
      setState(() { _weeklyError = e.toString(); _loadingWeekly = false; });
    }
  }

  Future<void> _pickDailyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dailyDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (picked != null) setState(() => _dailyDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          title: 'تقرير يومي',
          color: AppColors.neonOrange,
          icon: Icons.today_outlined,
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              GestureDetector(
                onTap: _pickDailyDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.neonOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neonOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.neonOrange, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _displayDate(_dailyDate),
                        style: AppText.body.copyWith(color: AppColors.neonOrange),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _loadingDaily
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonOrange),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search, color: AppColors.neonOrange),
                      onPressed: _fetchDaily,
                    ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingDaily)
          const LoadingWidget()
        else if (_dailyError != null)
          _buildErrorWidget(_dailyError!, _fetchDaily)
        else if (_dailyData != null)
          _buildResponseView(_dailyData)
        else
          Center(
            child: Text(
              'اختر تاريخاً ثم اضغط بحث',
              style: AppText.body,
              textDirection: TextDirection.rtl,
            ),
          ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.border),
        const SizedBox(height: 16),
        const _SectionHeader(
          title: 'تقرير أسبوعي',
          color: AppColors.neonBlue,
          icon: Icons.date_range_outlined,
        ),
        const SizedBox(height: 12),
        _DateRangeSelector(
          startDate: _startDate,
          endDate: _endDate,
          onFetch: _fetchWeekly,
          onStartChanged: (d) => setState(() => _startDate = d),
          onEndChanged: (d) => setState(() => _endDate = d),
          loading: _loadingWeekly,
        ),
        const SizedBox(height: 12),
        if (_loadingWeekly)
          const LoadingWidget()
        else if (_weeklyError != null)
          _buildErrorWidget(_weeklyError!, _fetchWeekly)
        else if (_weeklyData != null)
          _buildResponseView(_weeklyData)
        else
          Center(
            child: Text(
              'اختر نطاقاً زمنياً ثم اضغط بحث',
              style: AppText.body,
              textDirection: TextDirection.rtl,
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InventoryTab extends StatefulWidget {
  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  bool _loadingSnapshot = false;
  bool _loadingActivity = false;

  dynamic _snapshotData;
  dynamic _activityData;
  String? _snapshotError;
  String? _activityError;

  Future<void> _fetchSnapshot() async {
    setState(() { _loadingSnapshot = true; _snapshotError = null; });
    try {
      final res = await ApiService.get('/reports/inventory/snapshot');
      setState(() { _snapshotData = res.data; _loadingSnapshot = false; });
    } catch (e) {
      setState(() { _snapshotError = e.toString(); _loadingSnapshot = false; });
    }
  }

  Future<void> _fetchActivity() async {
    setState(() { _loadingActivity = true; _activityError = null; });
    try {
      final res = await ApiService.get('/reports/inventory/activity', params: {
        'startDate': _formatDate(_startDate),
        'endDate': _formatDate(_endDate),
      });
      setState(() { _activityData = res.data; _loadingActivity = false; });
    } catch (e) {
      setState(() { _activityError = e.toString(); _loadingActivity = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          title: 'لقطة المخزون الحالية',
          color: AppColors.neonCyan,
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Text('عرض حالة المخزون الآن', style: AppText.body, textDirection: TextDirection.rtl),
              const Spacer(),
              _loadingSnapshot
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
                    )
                  : ElevatedButton.icon(
                      onPressed: _fetchSnapshot,
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('جلب', style: TextStyle(fontFamily: 'Cairo')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingSnapshot)
          const LoadingWidget()
        else if (_snapshotError != null)
          _buildErrorWidget(_snapshotError!, _fetchSnapshot)
        else if (_snapshotData != null)
          _buildResponseView(_snapshotData)
        else
          Center(
            child: Text(
              'اضغط جلب لعرض بيانات المخزون',
              style: AppText.body,
              textDirection: TextDirection.rtl,
            ),
          ),
        const SizedBox(height: 24),
        const Divider(color: AppColors.border),
        const SizedBox(height: 16),
        const _SectionHeader(
          title: 'حركات المخزون',
          color: AppColors.neonGreen,
          icon: Icons.swap_horiz_outlined,
        ),
        const SizedBox(height: 12),
        _DateRangeSelector(
          startDate: _startDate,
          endDate: _endDate,
          onFetch: _fetchActivity,
          onStartChanged: (d) => setState(() => _startDate = d),
          onEndChanged: (d) => setState(() => _endDate = d),
          loading: _loadingActivity,
        ),
        const SizedBox(height: 12),
        if (_loadingActivity)
          const LoadingWidget()
        else if (_activityError != null)
          _buildErrorWidget(_activityError!, _fetchActivity)
        else if (_activityData != null)
          _buildResponseView(_activityData)
        else
          Center(
            child: Text(
              'اختر نطاقاً زمنياً ثم اضغط بحث',
              style: AppText.body,
              textDirection: TextDirection.rtl,
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AttendanceTab extends StatefulWidget {
  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _loading = false;
  dynamic _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/reports/attendance/activity', params: {
        'startDate': _formatDate(_startDate),
        'endDate': _formatDate(_endDate),
      });
      setState(() { _data = res.data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<_KpiItem> _extractKpis(dynamic data) {
    if (data == null) return [];
    final map = data is Map ? data : {};
    return [
      if (map['totalPresent'] != null || map['present'] != null)
        _KpiItem(
          label: 'الحضور',
          value: (map['totalPresent'] ?? map['present'] ?? 0).toString(),
          gradient: AppColors.successGrad,
          icon: Icons.check_circle_outline,
        ),
      if (map['totalAbsent'] != null || map['absent'] != null)
        _KpiItem(
          label: 'الغياب',
          value: (map['totalAbsent'] ?? map['absent'] ?? 0).toString(),
          gradient: AppColors.warningGrad,
          icon: Icons.cancel_outlined,
        ),
      if (map['totalLate'] != null || map['late'] != null)
        _KpiItem(
          label: 'التأخر',
          value: (map['totalLate'] ?? map['late'] ?? 0).toString(),
          gradient: AppColors.goldGrad,
          icon: Icons.timer_outlined,
        ),
      if (map['totalOvertime'] != null || map['overtime'] != null)
        _KpiItem(
          label: 'إضافي',
          value: (map['totalOvertime'] ?? map['overtime'] ?? 0).toString(),
          gradient: AppColors.primaryGrad,
          icon: Icons.more_time_outlined,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _extractKpis(_data);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          title: 'تقرير الحضور',
          color: AppColors.neonCyan,
          icon: Icons.fingerprint,
        ),
        const SizedBox(height: 12),
        _DateRangeSelector(
          startDate: _startDate,
          endDate: _endDate,
          onFetch: _fetch,
          onStartChanged: (d) => setState(() => _startDate = d),
          onEndChanged: (d) => setState(() => _endDate = d),
          loading: _loading,
        ),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          _buildErrorWidget(_error!, _fetch)
        else if (_data != null) ...[
          if (kpis.isNotEmpty) ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: kpis.map((k) => KpiCard(
                label: k.label,
                value: k.value,
                gradient: k.gradient,
                icon: k.icon,
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          _buildResponseView(_data),
        ] else
          Center(
            child: Text(
              'اختر نطاقاً زمنياً ثم اضغط بحث',
              style: AppText.body,
              textDirection: TextDirection.rtl,
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final LinearGradient gradient;
  final IconData icon;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.gradient,
    required this.icon,
  });
}

class _PayrollTab extends StatefulWidget {
  @override
  State<_PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<_PayrollTab> {
  late DateTime _month;
  bool _loading = false;
  dynamic _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/reports/payroll/activity', params: {
        'month': _formatMonth(_month),
      });
      setState(() { _data = res.data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<_KpiItem> _extractKpis(dynamic data) {
    if (data == null) return [];
    final map = data is Map ? data : {};
    return [
      if (map['totalPayroll'] != null || map['total'] != null)
        _KpiItem(
          label: 'إجمالي الرواتب',
          value: (map['totalPayroll'] ?? map['total'] ?? 0).toString(),
          gradient: AppColors.successGrad,
          icon: Icons.payments_outlined,
        ),
      if (map['employeeCount'] != null || map['employees'] != null || map['count'] != null)
        _KpiItem(
          label: 'عدد الموظفين',
          value: (map['employeeCount'] ?? map['employees'] ?? map['count'] ?? 0).toString(),
          gradient: AppColors.primaryGrad,
          icon: Icons.people_outline,
        ),
      if (map['averageSalary'] != null || map['average'] != null)
        _KpiItem(
          label: 'متوسط الراتب',
          value: (map['averageSalary'] ?? map['average'] ?? 0).toString(),
          gradient: AppColors.goldGrad,
          icon: Icons.trending_up_outlined,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _extractKpis(_data);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          title: 'تقرير الرواتب',
          color: AppColors.neonGreen,
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 12),
        _MonthSelector(
          month: _month,
          onChanged: (d) => setState(() => _month = d),
          onFetch: _fetch,
          loading: _loading,
        ),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          _buildErrorWidget(_error!, _fetch)
        else if (_data != null) ...[
          if (kpis.isNotEmpty) ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: kpis.map((k) => KpiCard(
                label: k.label,
                value: k.value,
                gradient: k.gradient,
                icon: k.icon,
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          _buildResponseView(_data),
        ] else
          Center(
            child: Text(
              'اختر شهراً ثم اضغط تحديث',
              style: AppText.body,
              textDirection: TextDirection.rtl,
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SalesTab extends StatefulWidget {
  @override
  State<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<_SalesTab> {
  late DateTime _month;
  bool _loading = false;
  dynamic _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _month = DateTime.now();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/reports/sales/monthly', params: {
        'month': _formatMonth(_month),
      });
      setState(() { _data = res.data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<_KpiItem> _extractKpis(dynamic data) {
    if (data == null) return [];
    final map = data is Map ? data : {};
    return [
      if (map['totalRevenue'] != null || map['revenue'] != null || map['total'] != null)
        _KpiItem(
          label: 'إجمالي الإيرادات',
          value: (map['totalRevenue'] ?? map['revenue'] ?? map['total'] ?? 0).toString(),
          gradient: AppColors.successGrad,
          icon: Icons.monetization_on_outlined,
        ),
      if (map['customerCount'] != null || map['customers'] != null)
        _KpiItem(
          label: 'عدد العملاء',
          value: (map['customerCount'] ?? map['customers'] ?? 0).toString(),
          gradient: AppColors.primaryGrad,
          icon: Icons.people_outline,
        ),
      if (map['invoiceCount'] != null || map['invoices'] != null)
        _KpiItem(
          label: 'عدد الفواتير',
          value: (map['invoiceCount'] ?? map['invoices'] ?? 0).toString(),
          gradient: AppColors.goldGrad,
          icon: Icons.receipt_outlined,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _extractKpis(_data);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(
          title: 'تقرير المبيعات',
          color: AppColors.neonGold,
          icon: Icons.trending_up_outlined,
        ),
        const SizedBox(height: 12),
        _MonthSelector(
          month: _month,
          onChanged: (d) => setState(() => _month = d),
          onFetch: _fetch,
          loading: _loading,
        ),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          _buildErrorWidget(_error!, _fetch)
        else if (_data != null) ...[
          if (kpis.isNotEmpty) ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: kpis.map((k) => KpiCard(
                label: k.label,
                value: k.value,
                gradient: k.gradient,
                icon: k.icon,
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          _buildResponseView(_data),
        ] else
          Center(
            child: Text(
              'اختر شهراً ثم اضغط تحديث',
              style: AppText.body,
              textDirection: TextDirection.rtl,
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
