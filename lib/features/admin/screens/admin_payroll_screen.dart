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

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key});
  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(
          children: [
            AiAppBar(title: 'الرواتب'),
            Container(
              color: c.bgCard,
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: AppText.label.copyWith(
                    color: AppColors.neonPurple, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    AppText.label.copyWith(color: AppColors.textSecondary),
                indicatorColor: AppColors.neonPurple,
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'ملخص'),
                  Tab(text: 'الرواتب اليومية'),
                  Tab(text: 'إعداد الرواتب'),
                  Tab(text: 'قواعد الخصومات'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _OverviewTab(),
                  _DailyPayrollTab(),
                  _SalaryConfigTab(),
                  _DeductionRulesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? _overview;
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ovRes = await ApiService.get('/payroll/admin/overview');
      final recRes = await ApiService.get('/payroll/');
      if (!mounted) return;
      final ovData = ovRes.data;
      final recData = recRes.data;
      setState(() {
        _overview = ovData is Map<String, dynamic> ? ovData : null;
        _records = recData is List
            ? recData
            : (recData['payrolls'] ?? recData['data'] ?? []);
        if (_records.length > 20) _records = _records.sublist(0, 20);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _calculateMonthly() async {
    final periodCtrl = TextEditingController(
        text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('احتساب شهري للكل', style: AppText.h3),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('أدخل الفترة بصيغة YYYY-MM',
                style: AppText.caption, textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
              child: TextField(
                controller: periodCtrl,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: '2024-01', border: InputBorder.none),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: Text('إلغاء', style: AppText.body.copyWith(color: AppColors.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('احتساب', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.post('/payroll/monthly/calculate',
            data: {'period': periodCtrl.text.trim()});
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(
          content: Text('تم الاحتساب الشهري بنجاح',
              style: TextStyle(fontFamily: 'Cairo'), textDirection: TextDirection.rtl),
          backgroundColor: AppColors.neonGreen,
        ));
        _load();
      } catch (_) {
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(
          content: Text('فشل الاحتساب',
              style: TextStyle(fontFamily: 'Cairo'), textDirection: TextDirection.rtl),
          backgroundColor: AppColors.neonRed,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const LoadingWidget();
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.neonPurple,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _calculateMonthly,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('احتساب شهري للكل', style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),
          if (_overview != null) ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                KpiCard(
                  label: 'إجمالي الرواتب',
                  value: _fmt(_overview!['totalPayroll']),
                  gradient: AppColors.primaryGrad,
                  icon: Icons.payments_outlined,
                ),
                KpiCard(
                  label: 'متوسط الراتب',
                  value: _fmt(_overview!['averageSalary']),
                  gradient: AppColors.goldGrad,
                  icon: Icons.trending_up_outlined,
                ),
                KpiCard(
                  label: 'عدد الموظفين',
                  value: '${_overview!['totalEmployees'] ?? '--'}',
                  gradient: AppColors.successGrad,
                  icon: Icons.people_outline,
                ),
                KpiCard(
                  label: 'رواتب مؤكّدة',
                  value: '${_overview!['confirmedPayrolls'] ?? '--'}',
                  gradient: AppColors.warningGrad,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Text('سجلات الرواتب الأخيرة',
              style: AppText.h3, textDirection: TextDirection.rtl),
          const SizedBox(height: 12),
          if (_records.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: EmptyStateWidget(
                  message: 'لا توجد سجلات رواتب',
                  icon: Icons.payments_outlined),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _PayrollRecordCard(record: _records[i]),
            ),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '--';
    final d = double.tryParse(v.toString());
    if (d == null) return v.toString();
    return d.toStringAsFixed(0);
  }
}

class _PayrollRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _PayrollRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final name = record['user']?['name'] ?? record['employeeName'] ?? '--';
    final month = record['month'] ?? record['period'] ?? '--';
    final base = record['baseSalary'] ?? record['base'] ?? '--';
    final total = record['totalSalary'] ?? record['netSalary'] ?? record['amount'] ?? '--';
    final overtime = record['overtimeHours'] ?? record['overtime'];

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.person_outline, color: AppColors.neonPurple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.h3),
                  const SizedBox(height: 2),
                  Text(month, style: AppText.caption),
                  if (overtime != null && overtime != 0)
                    Text('أوفرتايم: $overtime ساعة',
                        style:
                            AppText.caption.copyWith(color: AppColors.neonGold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.successGrad.createShader(b),
                  child: Text('$total ج.م',
                      style: AppText.h3.copyWith(color: Colors.white)),
                ),
                Text('أساسي: $base ج.م', style: AppText.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyPayrollTab extends StatefulWidget {
  const _DailyPayrollTab();
  @override
  State<_DailyPayrollTab> createState() => _DailyPayrollTabState();
}

class _DailyPayrollTabState extends State<_DailyPayrollTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<dynamic> _items = [];
  bool _loading = true;
  bool _calculating = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/payroll/daily');
      if (!mounted) return;
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['dailyPayrolls'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _calculateDate() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _calculating = true);
    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      await ApiService.post('/payroll/daily/calculate-date',
          data: {'date': dateStr});
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: const Text('تم احتساب الرواتب اليومية بنجاح',
            style: TextStyle(fontFamily: 'Cairo'), textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonGreen,
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: const Text('فشل الاحتساب',
            style: TextStyle(fontFamily: 'Cairo'), textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
      if (mounted) setState(() => _calculating = false);
    }
    if (mounted) setState(() => _calculating = false);
  }

  Future<void> _confirm(dynamic entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final id = entry['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      await ApiService.post('/payroll/daily/$id/confirm');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: const Text('تم التأكيد بنجاح',
            style: TextStyle(fontFamily: 'Cairo'), textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonGreen,
      ));
      _load();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: const Text('فشل التأكيد',
            style: TextStyle(fontFamily: 'Cairo'), textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.neonPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  String _dateLabel() {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.neonPurple.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppColors.neonPurple, size: 18),
                            const SizedBox(width: 8),
                            Text(_dateLabel(), style: AppText.body.copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _calculating ? null : _calculateDate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _calculating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('احتساب',
                            style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _items.isEmpty
                  ? const EmptyStateWidget(
                      message: 'لا توجد رواتب يومية',
                      icon: Icons.today_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.neonPurple,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _DailyEntryCard(entry: _items[i], onConfirm: _confirm),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _DailyEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final Future<void> Function(dynamic) onConfirm;
  const _DailyEntryCard({required this.entry, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final name = entry['user']?['name'] ?? entry['employeeName'] ?? '--';
    final date = entry['date'] ?? '--';
    final hours = entry['hoursWorked'] ?? entry['hours'] ?? '--';
    final dailyRate = entry['dailyRate'] ?? entry['rate'] ?? '--';
    final total = entry['totalPay'] ?? entry['total'] ?? entry['amount'] ?? '--';
    final deduction = entry['deduction'] ?? entry['deductionAmount'];
    final confirmed = entry['confirmed'] == true || entry['status'] == 'CONFIRMED';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.today_outlined,
                      color: AppColors.neonCyan, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppText.h3),
                      Text(date, style: AppText.caption),
                    ],
                  ),
                ),
                if (confirmed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('مؤكّد',
                        style: AppText.label.copyWith(color: AppColors.neonGreen)),
                  )
                else
                  TextButton(
                    onPressed: () => onConfirm(entry),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.neonOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      backgroundColor: AppColors.neonOrange.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('تأكيد',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _InfoChip(label: 'ساعات العمل', value: '$hours س', color: AppColors.neonBlue),
                _InfoChip(label: 'المعدل اليومي', value: '$dailyRate ج.م', color: AppColors.neonGold),
                _InfoChip(label: 'الإجمالي', value: '$total ج.م', color: AppColors.neonGreen),
                if (deduction != null && deduction != 0)
                  _InfoChip(label: 'خصم', value: '$deduction ج.م', color: AppColors.neonRed),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: color)),
          Text(value,
              style: AppText.label.copyWith(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SalaryConfigTab extends StatefulWidget {
  const _SalaryConfigTab();
  @override
  State<_SalaryConfigTab> createState() => _SalaryConfigTabState();
}

class _SalaryConfigTabState extends State<_SalaryConfigTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<dynamic> _roleConfigs = [];
  List<dynamic> _userSalaries = [];
  bool _loading = true;

  static const Map<String, String> _roleNames = {
    'ADMIN': 'مدير',
    'ENGINEER': 'مهندس',
    'ACCOUNTANT': 'محاسب',
    'WORKER': 'عامل',
    'SALES_REP': 'مندوب مبيعات',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final roleRes = await ApiService.get('/payroll/salary-config');
      final userRes = await ApiService.get('/payroll/admin/user-salaries');
      if (!mounted) return;
      final roleData = roleRes.data;
      final userData = userRes.data;
      setState(() {
        _roleConfigs = roleData is List ? roleData : (roleData['configs'] ?? roleData['data'] ?? []);
        _userSalaries = userData is List ? userData : (userData['users'] ?? userData['data'] ?? []);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _editRoleSalary(Map<String, dynamic> config) {
    final ctrl = TextEditingController(text: '${config['monthlySalary'] ?? ''}');
    final role = config['role'] ?? '';
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تعديل راتب: ${_roleNames[role] ?? role}',
            style: AppText.h3,
          ),
          content: _InputField(controller: ctrl, hint: 'الراتب الشهري (ج.م)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('إلغاء', style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final v = double.tryParse(ctrl.text.trim());
                if (v == null) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.put('/payroll/salary-config',
                      data: {'role': role, 'monthlySalary': v});
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text('تم تحديث راتب ${_roleNames[role] ?? role}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                        textDirection: TextDirection.rtl),
                    backgroundColor: AppColors.neonGreen,
                  ));
                  _load();
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: const Text('فشل التحديث',
                        style: TextStyle(fontFamily: 'Cairo'),
                        textDirection: TextDirection.rtl),
                    backgroundColor: AppColors.neonRed,
                  ));
                }
              },
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  void _editUserSalary(Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? user['userId']?.toString() ?? '';
    final name = user['name'] ?? user['user']?['name'] ?? '--';
    final ctrl = TextEditingController(
        text: '${user['monthlySalary'] ?? user['salaryOverride'] ?? ''}');
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('تعديل راتب: $name', style: AppText.h3),
          content: _InputField(controller: ctrl, hint: 'الراتب الشهري المخصص (ج.م)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('إلغاء', style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final v = double.tryParse(ctrl.text.trim());
                if (v == null || userId.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.put('/payroll/admin/user-salaries/$userId',
                      data: {'monthlySalary': v});
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text('تم تحديث راتب $name',
                        style: const TextStyle(fontFamily: 'Cairo'),
                        textDirection: TextDirection.rtl),
                    backgroundColor: AppColors.neonGreen,
                  ));
                  _load();
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: const Text('فشل التحديث',
                        style: TextStyle(fontFamily: 'Cairo'),
                        textDirection: TextDirection.rtl),
                    backgroundColor: AppColors.neonRed,
                  ));
                }
              },
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const LoadingWidget();
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.neonPurple,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'رواتب الأدوار الوظيفية', icon: Icons.work_outline, color: AppColors.neonPurple),
          const SizedBox(height: 10),
          if (_roleConfigs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: EmptyStateWidget(message: 'لا توجد إعدادات أدوار', icon: Icons.work_outline),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _roleConfigs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final cfg = _roleConfigs[i] as Map<String, dynamic>;
                final role = cfg['role'] ?? '';
                final salary = cfg['monthlySalary'] ?? cfg['salary'] ?? '--';
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.neonPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.badge_outlined,
                              color: AppColors.neonPurple, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_roleNames[role] ?? role, style: AppText.h3),
                              Text('$salary ج.م / شهر', style: AppText.caption),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.neonGold, size: 20),
                          onPressed: () => _editRoleSalary(cfg),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'رواتب مخصصة للموظفين', icon: Icons.person_outline, color: AppColors.neonCyan),
          const SizedBox(height: 10),
          if (_userSalaries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: EmptyStateWidget(message: 'لا توجد رواتب مخصصة', icon: Icons.person_outline),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userSalaries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final u = _userSalaries[i] as Map<String, dynamic>;
                final name = u['name'] ?? u['user']?['name'] ?? '--';
                final role = u['role'] ?? u['user']?['role'] ?? '';
                final salary = u['monthlySalary'] ?? u['salaryOverride'] ?? '--';
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_outline,
                              color: AppColors.neonCyan, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppText.h3),
                              Text(
                                '${_roleNames[role] ?? role} · $salary ج.م / شهر',
                                style: AppText.caption,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.neonGold, size: 20),
                          onPressed: () => _editUserSalary(u),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DeductionRulesTab extends StatefulWidget {
  const _DeductionRulesTab();
  @override
  State<_DeductionRulesTab> createState() => _DeductionRulesTabState();
}

class _DeductionRulesTabState extends State<_DeductionRulesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<dynamic> _rules = [];
  bool _loading = true;

  static const Map<String, String> _typeNames = {
    'LATE_ARRIVAL': 'تأخر في الوصول',
    'EARLY_CHECKOUT': 'مغادرة مبكرة',
    'UNEXCUSED_ABSENCE': 'غياب بدون عذر',
    'SICK_LEAVE': 'إجازة مرضية',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/payroll/admin/deduction-rules');
      if (!mounted) return;
      final data = res.data;
      setState(() {
        _rules = data is List ? data : (data['rules'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateRule(Map<String, dynamic> rule, {bool? isActive}) async {
    final messenger = ScaffoldMessenger.of(context);
    final type = rule['type'] ?? '';
    if (type.isEmpty) return;
    try {
      await ApiService.put('/payroll/admin/deduction-rules/$type', data: {
        'isActive': isActive ?? rule['isActive'],
        'thresholdMinutes': rule['thresholdMinutes'],
        'deductionValue': rule['deductionValue'],
      });
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('تم تحديث قاعدة ${_typeNames[type] ?? type}',
            style: const TextStyle(fontFamily: 'Cairo'),
            textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonGreen,
      ));
      _load();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: const Text('فشل التحديث',
            style: TextStyle(fontFamily: 'Cairo'),
            textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
    }
  }

  void _editRule(Map<String, dynamic> rule) {
    final type = rule['type'] ?? '';
    final threshCtrl = TextEditingController(
        text: '${rule['thresholdMinutes'] ?? ''}');
    final deductCtrl = TextEditingController(
        text: '${rule['deductionValue'] ?? ''}');
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تعديل: ${_typeNames[type] ?? type}',
            style: AppText.h3,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InputField(
                  controller: threshCtrl, hint: 'الحد الزمني (دقائق)', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _InputField(
                  controller: deductCtrl, hint: 'قيمة الخصم', keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('إلغاء', style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final thresh = int.tryParse(threshCtrl.text.trim());
                final deduct = double.tryParse(deductCtrl.text.trim());
                Navigator.pop(ctx);
                try {
                  await ApiService.put('/payroll/admin/deduction-rules/$type', data: {
                    'isActive': rule['isActive'],
                    'thresholdMinutes': thresh ?? rule['thresholdMinutes'],
                    'deductionValue': deduct ?? rule['deductionValue'],
                  });
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text('تم تحديث ${_typeNames[type] ?? type}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                        textDirection: TextDirection.rtl),
                    backgroundColor: AppColors.neonGreen,
                  ));
                  _load();
                } catch (_) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: const Text('فشل التحديث',
                        style: TextStyle(fontFamily: 'Cairo'),
                        textDirection: TextDirection.rtl),
                    backgroundColor: AppColors.neonRed,
                  ));
                }
              },
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const LoadingWidget();
    if (_rules.isEmpty) {
      return const EmptyStateWidget(
          message: 'لا توجد قواعد خصومات', icon: Icons.rule_outlined);
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.neonPurple,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rules.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final rule = _rules[i] as Map<String, dynamic>;
          final type = rule['type'] ?? '';
          final isActive = rule['isActive'] == true;
          final threshold = rule['thresholdMinutes'];
          final deduction = rule['deductionValue'];
          final color = isActive ? AppColors.neonGreen : AppColors.textSecondary;

          return GlassCard(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.rule_outlined, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _typeNames[type] ?? type,
                          style: AppText.h3,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.neonGold, size: 20),
                        onPressed: () => _editRule(rule),
                      ),
                      Switch(
                        value: isActive,
                        activeThumbColor: AppColors.neonGreen,
                        inactiveThumbColor: AppColors.textSecondary,
                        onChanged: (v) => _updateRule(rule, isActive: v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (threshold != null)
                        _InfoChip(
                          label: 'الحد الزمني',
                          value: '$threshold دقيقة',
                          color: AppColors.neonBlue,
                        ),
                      if (deduction != null)
                        _InfoChip(
                          label: 'قيمة الخصم',
                          value: '$deduction ج.م',
                          color: AppColors.neonRed,
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          isActive ? 'مفعّل' : 'معطّل',
                          style: AppText.label.copyWith(color: color),
                        ),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: AppText.h3.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
