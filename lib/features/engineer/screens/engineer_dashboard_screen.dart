import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/animated_card.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerDashboardScreen extends StatefulWidget {
  const EngineerDashboardScreen({super.key});
  @override
  State<EngineerDashboardScreen> createState() => _EngineerDashboardScreenState();
}

class _EngineerDashboardScreenState extends State<EngineerDashboardScreen> {
  List<dynamic> _production  = [];
  List<dynamic> _maintenance = [];
  List<dynamic> _machines    = [];
  List<dynamic> _electricity = [];
  List<dynamic> _quality     = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/production/me'),
        ApiService.get('/maintenance/me'),
        ApiService.get('/machines/'),
        ApiService.get('/electricity/readings'),
        ApiService.get('/quality-checks/me'),
      ]);

      List<dynamic> _parse(dynamic raw) {
        if (raw is List) return raw;
        if (raw is Map) {
          for (final key in ['data', 'items', 'records', 'results']) {
            if (raw[key] is List) return raw[key] as List;
          }
        }
        return [];
      }

      if (!mounted) return;
      setState(() {
        _production  = _parse(results[0].data);
        _maintenance = _parse(results[1].data);
        _machines    = _parse(results[2].data);
        _electricity = _parse(results[3].data);
        _quality     = _parse(results[4].data);
        _loading     = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int get _productionThisMonth {
    final now = DateTime.now();
    return _production.where((p) {
      final raw = p['createdAt'] ?? p['date'] ?? '';
      try {
        final d = DateTime.parse(raw.toString());
        return d.year == now.year && d.month == now.month;
      } catch (_) { return false; }
    }).length;
  }

  Map<String, dynamic>? get _lastReading =>
      _electricity.isNotEmpty ? _electricity.first as Map<String, dynamic>? : null;

  Color _machineStatusColor(String? status) {
    switch (status) {
      case 'OPERATIONAL':    return AppColors.neonGreen;
      case 'UNDER_MAINTENANCE': return AppColors.neonGold;
      case 'BROKEN':         return AppColors.neonRed;
      case 'OFFLINE':        return AppColors.neonOrange;
      case 'DECOMMISSIONED': return AppColors.textMuted;
      default:               return AppColors.textSecondary;
    }
  }

  String _machineStatusLabel(String? status) {
    switch (status) {
      case 'OPERATIONAL':       return 'تشغيلية';
      case 'UNDER_MAINTENANCE': return 'صيانة';
      case 'BROKEN':            return 'معطلة';
      case 'OFFLINE':           return 'غير متصلة';
      case 'DECOMMISSIONED':    return 'مستبعدة';
      default:                  return status ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 0),
      body: AiBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.bgCard,
              elevation: 0,
              toolbarHeight: 64,
              automaticallyImplyLeading: false,
              flexibleSpace: AiAppBar(
                title: 'لوحة المهندس',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                    onPressed: _load,
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () => context.push('/notifications'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Welcome card ──────────────────────────────────────
                  AnimatedCard(
                    child: GlassCard(
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مرحباً، ${user?.name ?? 'مهندس'}',
                                  style: AppText.h2, textDirection: TextDirection.rtl),
                              const SizedBox(height: 4),
                              Text('متابعة حالة الآلات والصيانة',
                                  style: AppText.body, textDirection: TextDirection.rtl),
                            ],
                          )),
                          ShaderMask(
                            shaderCallback: (b) => AppColors.successGrad.createShader(b),
                            child: const Icon(Icons.engineering, size: 40, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── KPI cards ─────────────────────────────────────────
                  if (_loading)
                    const LoadingWidget()
                  else ...[
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        AnimatedCard(delay: 0, child: KpiCard(
                          label: 'إنتاجي (هذا الشهر)',
                          value: '$_productionThisMonth',
                          gradient: AppColors.successGrad,
                          icon: Icons.factory_outlined,
                        )),
                        AnimatedCard(delay: 100, child: KpiCard(
                          label: 'طلبات الصيانة',
                          value: '${_maintenance.length}',
                          gradient: AppColors.warningGrad,
                          icon: Icons.build_outlined,
                        )),
                        AnimatedCard(delay: 200, child: KpiCard(
                          label: 'الآلات',
                          value: '${_machines.length}',
                          gradient: AppColors.primaryGrad,
                          icon: Icons.precision_manufacturing_outlined,
                        )),
                        AnimatedCard(delay: 300, child: KpiCard(
                          label: 'فحوصات الجودة',
                          value: '${_quality.length}',
                          gradient: AppColors.goldGrad,
                          icon: Icons.verified_outlined,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Last electricity reading ──────────────────────
                    if (_lastReading != null)
                      AnimatedCard(
                        delay: 100,
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.neonGold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.bolt, color: AppColors.neonGold, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('آخر قراءة كهرباء',
                                        style: AppText.caption, textDirection: TextDirection.rtl),
                                    Text(
                                      '${_lastReading!['consumption'] ?? '--'} كيلوواط',
                                      style: AppText.h3.copyWith(color: AppColors.neonGold),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                (_lastReading!['date'] ?? _lastReading!['createdAt'] ?? '')
                                    .toString()
                                    .substring(0, 10),
                                style: AppText.label.copyWith(color: AppColors.textSecondary),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_lastReading != null) const SizedBox(height: 16),

                    // ── Machines list ─────────────────────────────────
                    if (_machines.isNotEmpty)
                      AnimatedCard(
                        delay: 200,
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(textDirection: TextDirection.rtl, children: [
                                const Icon(Icons.precision_manufacturing_outlined,
                                    color: AppColors.neonCyan, size: 20),
                                const SizedBox(width: 8),
                                Text('الآلات', style: AppText.h3),
                              ]),
                              const SizedBox(height: 12),
                              ..._machines.take(8).map((m) {
                                final name   = m['name'] ?? '--';
                                final status = m['status'] as String?;
                                final color  = _machineStatusColor(status);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(textDirection: TextDirection.rtl, children: [
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(name.toString(),
                                            style: AppText.body.copyWith(
                                                color: AppColors.textPrimary),
                                            textDirection: TextDirection.rtl),
                                      ]),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _machineStatusLabel(status),
                                          style: AppText.label.copyWith(color: color),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                    if (_machines.isNotEmpty) const SizedBox(height: 16),

                    // ── Quick access ──────────────────────────────────
                    AnimatedCard(
                      delay: 300,
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(textDirection: TextDirection.rtl, children: [
                              const Icon(Icons.link, color: AppColors.neonCyan, size: 20),
                              const SizedBox(width: 8),
                              Text('الوصول السريع', style: AppText.h3),
                            ]),
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              _quickBtn('صيانة', Icons.build_outlined, AppColors.neonCyan,
                                  () => context.push('/engineer/maintenance')),
                              _quickBtn('جودة', Icons.verified_outlined, AppColors.neonGreen,
                                  () => context.push('/engineer/quality')),
                              _quickBtn('قطع غيار', Icons.settings_outlined, AppColors.neonGold,
                                  () => context.push('/engineer/spare-parts')),
                              _quickBtn('وثائق', Icons.description_outlined, AppColors.neonPurple,
                                  () => context.push('/engineer/documents')),
                              _quickBtn('كهرباء', Icons.bolt_outlined, AppColors.neonOrange,
                                  () => context.push('/engineer/electricity')),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: AppText.caption.copyWith(color: color)),
          ]),
        ),
      );
}
