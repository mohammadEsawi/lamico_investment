import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/worker_nav.dart';

class WorkerPayrollScreen extends StatefulWidget {
  const WorkerPayrollScreen({super.key});
  @override
  State<WorkerPayrollScreen> createState() => _WorkerPayrollScreenState();
}

class _WorkerPayrollScreenState extends State<WorkerPayrollScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  List<dynamic> _payroll   = [];
  List<dynamic> _daily     = [];
  Map<String, dynamic>? _config;
  bool _loadingPayroll = true;
  bool _loadingDaily   = true;
  bool _loadingConfig  = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadPayroll();
    _loadDaily();
    _loadConfig();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadPayroll() async {
    setState(() => _loadingPayroll = true);
    try {
      final res = await ApiService.get('/payroll/me');
      final data = res.data;
      setState(() {
        _payroll = data is List ? data : (data['payroll'] ?? data['data'] ?? []);
        _loadingPayroll = false;
      });
    } catch (_) { setState(() => _loadingPayroll = false); }
  }

  Future<void> _loadDaily() async {
    setState(() => _loadingDaily = true);
    try {
      final res = await ApiService.get('/payroll/daily/me');
      final data = res.data;
      setState(() {
        _daily = data is List ? data : (data['daily'] ?? data['data'] ?? []);
        _loadingDaily = false;
      });
    } catch (_) { setState(() => _loadingDaily = false); }
  }

  Future<void> _loadConfig() async {
    setState(() => _loadingConfig = true);
    try {
      final res = await ApiService.get('/payroll/salary-config');
      setState(() {
        _config = res.data as Map<String, dynamic>?;
        _loadingConfig = false;
      });
    } catch (_) { setState(() => _loadingConfig = false); }
  }

  Widget _buildMonthly() {
    if (_loadingPayroll) return const LoadingWidget();
    if (_payroll.isEmpty) {
      return const EmptyStateWidget(message: 'لا توجد سجلات رواتب', icon: Icons.payments_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadPayroll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payroll.length,
        separatorBuilder: (_, i) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = _payroll[i];
          return GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p['period'] ?? p['month'] ?? '--',
                        style: AppText.h3, textDirection: TextDirection.rtl),
                    Text('${p['netSalary'] ?? p['net'] ?? p['amount'] ?? '--'} ج.م',
                        style: AppText.h3.copyWith(color: AppColors.neonGreen)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الأساسي: ${p['baseSalary'] ?? '--'} ج.م', style: AppText.caption),
                    Text('الأوفرتايم: ${p['overtimePay'] ?? 0} ج.م', style: AppText.caption),
                  ],
                ),
                if (p['deductions'] != null || p['bonus'] != null)
                  Row(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الخصومات: ${p['deductions'] ?? 0} ج.م', style: AppText.caption),
                      Text('المكافآت: ${p['bonus'] ?? 0} ج.م', style: AppText.caption),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaily() {
    if (_loadingDaily) return const LoadingWidget();
    if (_daily.isEmpty) {
      return const EmptyStateWidget(message: 'لا توجد سجلات يومية', icon: Icons.today_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadDaily,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _daily.length,
        separatorBuilder: (_, i) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final d = _daily[i];
          return GlassCard(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.today_outlined, color: AppColors.neonCyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['date']?.toString().substring(0, 10) ?? '--',
                          style: AppText.h3, textDirection: TextDirection.rtl),
                      Text('ساعات: ${d['hoursWorked'] ?? d['hours'] ?? '--'}',
                          style: AppText.caption, textDirection: TextDirection.rtl),
                    ],
                  ),
                ),
                Text('${d['dailyAmount'] ?? d['amount'] ?? '--'} ج.م',
                    style: AppText.h3.copyWith(color: AppColors.neonCyan)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfig() {
    if (_loadingConfig) return const LoadingWidget();
    if (_config == null) {
      return const EmptyStateWidget(message: 'لا توجد بيانات الراتب', icon: Icons.settings_outlined);
    }
    final entries = _config!.entries.where((e) => e.value != null).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(textDirection: TextDirection.rtl, children: [
                const Icon(Icons.settings_outlined, color: AppColors.neonPurple),
                const SizedBox(width: 8),
                Text('إعدادات الراتب', style: AppText.h3),
              ]),
              const SizedBox(height: 16),
              ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: AppText.caption, textDirection: TextDirection.rtl),
                    Text('${e.value}', style: AppText.body.copyWith(color: AppColors.neonPurple)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const WorkerNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'راتبي'),
          Container(
            color: AppColors.bgCard,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.neonGreen,
              labelColor: AppColors.neonGreen,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.payments_outlined),  text: 'الشهري'),
                Tab(icon: Icon(Icons.today_outlined),      text: 'اليومي'),
                Tab(icon: Icon(Icons.settings_outlined),   text: 'الإعدادات'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_buildMonthly(), _buildDaily(), _buildConfig()],
            ),
          ),
        ]),
      ),
    );
  }
}
