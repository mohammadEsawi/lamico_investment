import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminProductionScreen extends StatefulWidget {
  const AdminProductionScreen({super.key});
  @override
  State<AdminProductionScreen> createState() => _AdminProductionScreenState();
}

class _AdminProductionScreenState extends State<AdminProductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic>? _overview;
  List<dynamic> _records    = [];
  List<dynamic> _electricity = [];
  bool _loading = true;

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
        ApiService.get('/production/admin/overview'),
        ApiService.get('/production/all'),
        ApiService.get('/electricity/readings'),
      ]);

      setState(() {
        _overview    = results[0].data is Map ? results[0].data as Map<String, dynamic> : null;
        final rRaw   = results[1].data;
        _records     = rRaw is List ? rRaw : (rRaw['records'] ?? rRaw['data'] ?? []);
        AppDate.sortDesc(_records);
        final eRaw   = results[2].data;
        _electricity = eRaw is List ? eRaw : (eRaw['readings'] ?? eRaw['data'] ?? []);
        AppDate.sortDesc(_electricity, field: 'date');
        _loading     = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الإنتاج والكهرباء'),
          Container(
            color: AppColors.bgCard,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.neonPurple,
              labelColor: AppColors.neonPurple,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'نظرة عامة'),
                Tab(text: 'سجلات الإنتاج'),
                Tab(text: 'الكهرباء'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : TabBarView(
                    controller: _tab,
                    children: [
                      _OverviewTab(overview: _overview),
                      _RecordsTab(records: _records, onRefresh: _load),
                      _ElectricityTab(readings: _electricity, onRefresh: _load),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? overview;
  const _OverviewTab({required this.overview});

  @override
  Widget build(BuildContext context) {
    if (overview == null) {
      return const EmptyStateWidget(message: 'لا توجد بيانات إنتاج بعد');
    }

    final totalPieces  = overview?['totalPieces']  ?? overview?['total']        ?? 0;
    final totalCartons = overview?['totalCartons']  ?? overview?['cartons']      ?? 0;
    final totalHdpe    = overview?['totalHdpe']     ?? overview?['hdpe']         ?? 0;
    final totalLdpe    = overview?['totalLdpe']     ?? overview?['ldpe']         ?? 0;
    final totalPet     = overview?['totalPet']      ?? overview?['pet']          ?? 0;
    final workers      = overview?['workersCount']  ?? overview?['users']        ?? 0;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // KPI Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            KpiCard(
              label: 'إجمالي الإنتاج (قطعة)',
              value: '$totalPieces',
              gradient: AppColors.successGrad,
              icon: Icons.inventory_2_outlined,
            ),
            KpiCard(
              label: 'إجمالي الكراتين',
              value: '$totalCartons',
              gradient: AppColors.primaryGrad,
              icon: Icons.inbox_outlined,
            ),
            KpiCard(
              label: 'عدد العمال',
              value: '$workers',
              gradient: AppColors.goldGrad,
              icon: Icons.people_outline,
            ),
            KpiCard(
              label: 'سجلات الإنتاج',
              value: '${overview?['recordsCount'] ?? overview?['count'] ?? 0}',
              gradient: AppColors.warningGrad,
              icon: Icons.assignment_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Raw materials card
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(textDirection: TextDirection.rtl, children: [
              const Icon(Icons.science, color: AppColors.neonCyan, size: 20),
              const SizedBox(width: 8),
              Text('استهلاك المواد الخام', style: AppText.h3),
            ]),
            const SizedBox(height: 16),
            _MatRow('HDPE', '$totalHdpe كغ', AppColors.neonGreen),
            const SizedBox(height: 10),
            _MatRow('LDPE', '$totalLdpe كغ', AppColors.neonBlue),
            const SizedBox(height: 10),
            _MatRow('PET',  '$totalPet كغ',  AppColors.neonCyan),
          ]),
        ),

        // Shift breakdown if available
        if ((overview?['byShift'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(textDirection: TextDirection.rtl, children: [
                const Icon(Icons.schedule, color: AppColors.neonPurple, size: 20),
                const SizedBox(width: 8),
                Text('الإنتاج حسب الشفت', style: AppText.h3),
              ]),
              const SizedBox(height: 12),
              ...(overview!['byShift'] as List).map((s) => _ShiftRow(shift: s)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _MatRow extends StatelessWidget {
  final String name;
  final String value;
  final Color color;
  const _MatRow(this.name, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.rtl,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(textDirection: TextDirection.rtl, children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(name, style: AppText.body, textDirection: TextDirection.rtl),
      ]),
      Text(value, style: AppText.body.copyWith(color: color, fontWeight: FontWeight.w600),
          textDirection: TextDirection.rtl),
    ],
  );
}

class _ShiftRow extends StatelessWidget {
  final Map<String, dynamic> shift;
  const _ShiftRow({required this.shift});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.neonPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('شفت ${shift['name'] ?? shift['shift'] ?? '--'}',
              style: AppText.label.copyWith(color: AppColors.neonPurple),
              textDirection: TextDirection.rtl),
        ),
        Text('${shift['totalPieces'] ?? shift['total'] ?? 0} قطعة',
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            textDirection: TextDirection.rtl),
      ],
    ),
  );
}

// ─── Records Tab ──────────────────────────────────────────────────────────────

class _RecordsTab extends StatelessWidget {
  final List<dynamic> records;
  final Future<void> Function() onRefresh;
  const _RecordsTab({required this.records, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const EmptyStateWidget(message: 'لا توجد سجلات إنتاج', icon: Icons.inventory_2_outlined);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ProdCard(record: records[i]),
      ),
    );
  }
}

class _ProdCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _ProdCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr  = AppDate.format(record['createdAt'] ?? record['date']);
    final user     = record['user']?['fullName'] ?? '--';
    final shift    = record['shift']?['name'] ?? '--';
    final machine  = record['machine']?['name'] ?? '--';
    final total    = record['totalPieces'] ?? 0;
    final cartons  = record['cartonsCount'] ?? 0;
    final hdpe     = record['rawHdpeUsed'];
    final ldpe     = record['rawLdpeUsed'];
    final pet      = record['rawPetUsed'];
    final isCaps   = hdpe != null || ldpe != null;
    final color    = isCaps ? AppColors.neonOrange : AppColors.neonCyan;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(textDirection: TextDirection.rtl, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(isCaps ? Icons.inbox_outlined : Icons.science_outlined,
                    color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user, style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    textDirection: TextDirection.rtl),
                Text('$dateStr | شفت $shift | $machine',
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
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: AppText.label.copyWith(color: c), textDirection: TextDirection.rtl),
  );
}

// ─── Electricity Tab ──────────────────────────────────────────────────────────

class _ElectricityTab extends StatelessWidget {
  final List<dynamic> readings;
  final Future<void> Function() onRefresh;
  const _ElectricityTab({required this.readings, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const EmptyStateWidget(message: 'لا توجد قراءات كهرباء', icon: Icons.bolt_outlined);
    }

    // Summary totals
    double totalConsumption = 0;
    double totalCost = 0;
    for (final r in readings) {
      totalConsumption += (r['consumption'] as num?)?.toDouble() ?? 0;
      totalCost        += (r['shiftCost']   as num?)?.toDouble() ?? 0;
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Summary
        Row(children: [
          Expanded(child: _SumCard(
            label: 'إجمالي الاستهلاك',
            value: '${totalConsumption.toStringAsFixed(1)} كيلوواط',
            color: AppColors.neonGold,
            icon: Icons.bolt,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SumCard(
            label: 'إجمالي التكلفة',
            value: '${totalCost.toStringAsFixed(2)} ج.م',
            color: AppColors.neonOrange,
            icon: Icons.payments_outlined,
          )),
        ]),
        const SizedBox(height: 16),

        ...readings.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ElecCard(reading: r),
        )),
      ]),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SumCard({required this.label, required this.value,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(label, style: AppText.caption, textDirection: TextDirection.rtl),
      const SizedBox(height: 4),
      Text(value, style: AppText.h3.copyWith(color: color),
          textDirection: TextDirection.rtl),
    ]),
  );
}

class _ElecCard extends StatelessWidget {
  final Map<String, dynamic> reading;
  const _ElecCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final dateStr = AppDate.format(reading['date']);
    final shift   = reading['shift']?['name'] ?? '--';
    final by      = reading['recordedBy']?['fullName'] ?? '--';
    final start   = reading['startReading'] ?? 0;
    final end     = reading['endReading'] ?? 0;
    final cons    = reading['consumption'] ?? 0;
    final cost    = reading['shiftCost'] ?? 0;
    final notes   = reading['notes'] as String?;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(textDirection: TextDirection.rtl, children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.neonGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt, color: AppColors.neonGold, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(by, style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                    textDirection: TextDirection.rtl),
                Text('$dateStr | شفت $shift',
                    style: AppText.caption, textDirection: TextDirection.rtl),
              ]),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$cons كيلوواط',
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
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: AppText.label.copyWith(color: c), textDirection: TextDirection.rtl),
  );
}
