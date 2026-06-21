import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/accountant_nav.dart';

class AccountantReportsScreen extends StatefulWidget {
  const AccountantReportsScreen({super.key});
  @override
  State<AccountantReportsScreen> createState() => _AccountantReportsScreenState();
}

class _AccountantReportsScreenState extends State<AccountantReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _reports = [];
  bool _loading = true;

  Map<String, dynamic>? _liveData;
  bool _loadingLive = false;
  String _liveType  = 'production/daily';
  String _liveDate  = '';

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
      final res = await ApiService.get('/financial-reports');
      final data = res.data;
      setState(() {
        _reports = data is List ? data : (data['reports'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _loadLive() async {
    setState(() { _loadingLive = true; _liveData = null; });
    try {
      final parts = _liveType.split('/');
      final type  = parts[0];
      final sub   = parts.length > 1 ? parts[1] : '';
      String path;
      switch (type) {
        case 'production':
          path = sub == 'weekly' ? '/reports/production/weekly' : '/reports/production/daily';
          if (_liveDate.isNotEmpty) path += '?date=$_liveDate';
          break;
        case 'sales':
          path = sub == 'yearly' ? '/reports/sales/yearly' : '/reports/sales/monthly';
          if (_liveDate.isNotEmpty) path += '?month=$_liveDate';
          break;
        case 'inventory':
          path = sub == 'snapshot' ? '/reports/inventory/snapshot' : '/reports/inventory/activity';
          if (_liveDate.isNotEmpty) path += '?date=$_liveDate';
          break;
        case 'attendance':
          path = '/reports/attendance/activity';
          if (_liveDate.isNotEmpty) path += '?date=$_liveDate';
          break;
        case 'payroll':
          path = '/reports/payroll/activity';
          if (_liveDate.isNotEmpty) path += '?month=$_liveDate';
          break;
        default:
          path = '/financial-reports';
      }
      final res = await ApiService.get(path);
      setState(() { _liveData = res.data as Map<String, dynamic>?; _loadingLive = false; });
    } catch (_) { setState(() => _loadingLive = false); }
  }

  static const _reportTypes = [
    ('production/daily',   'إنتاج يومي',       AppColors.neonGreen),
    ('production/weekly',  'إنتاج أسبوعي',      AppColors.neonGreen),
    ('sales/monthly',      'مبيعات شهرية',      AppColors.neonGold),
    ('sales/yearly',       'مبيعات سنوية',      AppColors.neonGold),
    ('inventory/activity', 'نشاط المخزون',      AppColors.neonCyan),
    ('inventory/snapshot', 'لقطة المخزون',      AppColors.neonCyan),
    ('attendance/activity','نشاط الحضور',       AppColors.neonPurple),
    ('payroll/activity',   'نشاط الرواتب',      AppColors.neonOrange),
  ];

  Widget _buildLive() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('نوع التقرير', style: AppText.h3, textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _reportTypes.map((t) {
                final selected = _liveType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _liveType = t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? t.$3.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? t.$3 : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(t.$2,
                        style: AppText.caption.copyWith(
                            color: selected ? t.$3 : AppColors.textSecondary),
                        textDirection: TextDirection.rtl),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
              child: TextField(
                textAlign: TextAlign.right,
                onChanged: (v) => _liveDate = v,
                style: AppText.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                    hintText: 'التاريخ / الشهر (اختياري)',
                    hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
                    border: InputBorder.none, isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _loadLive,
                icon: const Icon(Icons.bar_chart_outlined, color: Colors.white, size: 18),
                label: const Text('عرض التقرير',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (_loadingLive) const LoadingWidget(),
        if (_liveData != null) ..._buildLiveCards(),
      ],
    );
  }

  List<Widget> _buildLiveCards() {
    final data = _liveData!;
    final entries = data.entries
        .where((e) => e.value != null && e.value is! Map && e.value is! List)
        .toList();
    final lists = data.entries.where((e) => e.value is List).toList();

    return [
      if (entries.isNotEmpty) GlassCard(
        child: Wrap(
          spacing: 16, runSpacing: 12,
          children: entries.map((e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${e.value}', style: AppText.h3.copyWith(color: AppColors.neonPurple)),
              Text(e.key, style: AppText.caption, textDirection: TextDirection.rtl),
            ],
          )).toList(),
        ),
      ),
      ...lists.map((e) {
        final list = e.value as List;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          Text(e.key, style: AppText.h3, textDirection: TextDirection.rtl),
          const SizedBox(height: 8),
          ...list.take(10).map((item) {
            if (item is Map) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: item.entries.map((en) => Text(
                      '${en.key}: ${en.value}',
                      style: AppText.caption, textDirection: TextDirection.rtl,
                    )).toList()),
                ),
              );
            }
            return Text('$item', style: AppText.caption);
          }),
        ]);
      }),
    ];
  }

  Widget _buildSaved() {
    if (_loading) return const LoadingWidget();
    if (_reports.isEmpty) {
      return const EmptyStateWidget(message: 'لا توجد تقارير محفوظة', icon: Icons.bar_chart_outlined);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        separatorBuilder: (_, i) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final r = _reports[i];
          return GlassCard(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bar_chart, color: AppColors.neonPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['title'] ?? r['name'] ?? '--',
                          style: AppText.h3, textDirection: TextDirection.rtl),
                      Text(r['period'] ?? r['month'] ?? '--',
                          style: AppText.caption, textDirection: TextDirection.rtl),
                      Text(r['createdAt']?.toString().substring(0, 10) ?? '--',
                          style: AppText.label),
                    ],
                  ),
                ),
                const Icon(Icons.download_outlined, color: AppColors.neonPurple, size: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AccountantNav(selectedIndex: 2),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'التقارير المالية'),
          Container(
            color: AppColors.bgCard,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.neonPurple,
              labelColor: AppColors.neonPurple,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.analytics_outlined), text: 'تقارير'),
                Tab(icon: Icon(Icons.folder_outlined),    text: 'المحفوظة'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_buildLive(), _buildSaved()],
            ),
          ),
        ]),
      ),
    );
  }
}
