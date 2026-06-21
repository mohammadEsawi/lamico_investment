import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminWorkerOverviewScreen extends StatefulWidget {
  const AdminWorkerOverviewScreen({super.key});
  @override
  State<AdminWorkerOverviewScreen> createState() => _AdminWorkerOverviewScreenState();
}

class _AdminWorkerOverviewScreenState extends State<AdminWorkerOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<dynamic> _workers = [];
  List<dynamic> _alerts = [];
  List<dynamic> _kaizen = [];
  bool _loadingWorkers = true;
  bool _loadingAlerts = true;
  bool _loadingKaizen = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadWorkers();
    _loadAlerts();
    _loadKaizen();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadWorkers() async {
    setState(() => _loadingWorkers = true);
    try {
      final res = await ApiService.get('/worker-tools/admin/overview');
      final data = res.data;
      setState(() {
        _workers = data is List ? data : (data['workers'] ?? data['data'] ?? []);
        _loadingWorkers = false;
      });
    } catch (_) { setState(() => _loadingWorkers = false); }
  }

  Future<void> _loadAlerts() async {
    setState(() => _loadingAlerts = true);
    try {
      final res = await ApiService.get('/worker-tools/admin/machine-stop-alerts');
      final data = res.data;
      setState(() {
        _alerts = data is List ? data : (data['alerts'] ?? data['data'] ?? []);
        _loadingAlerts = false;
      });
    } catch (_) { setState(() => _loadingAlerts = false); }
  }

  Future<void> _loadKaizen() async {
    setState(() => _loadingKaizen = true);
    try {
      final res = await ApiService.get('/worker-tools/admin/kaizen');
      final data = res.data;
      setState(() {
        _kaizen = data is List ? data : (data['suggestions'] ?? data['data'] ?? []);
        _loadingKaizen = false;
      });
    } catch (_) { setState(() => _loadingKaizen = false); }
  }

  Future<void> _resolveAlert(Map<String, dynamic> alert) async {
    final notesCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('حل التنبيه', style: AppText.h3, textDirection: TextDirection.rtl),
            const SizedBox(height: 4),
            Text('الآلة: ${alert['machine']?['name'] ?? '--'}',
                style: AppText.caption, textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'ملاحظات الحل',
                filled: true, fillColor: AppColors.bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ApiService.patch(
                        '/worker-tools/admin/machine-stop-alerts/${alert['id']}/resolve',
                        data: {if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text});
                    _loadAlerts();
                  } catch (_) {}
                },
                child: const Text('تأكيد الحل',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _reviewKaizen(Map<String, dynamic> k) async {
    String status = k['status'] ?? 'PENDING';
    final notesCtrl = TextEditingController(text: k['adminNotes'] ?? '');
    const statuses = {
      'PENDING': 'معلق',
      'UNDER_REVIEW': 'قيد المراجعة',
      'APPROVED': 'موافق',
      'REJECTED': 'مرفوض',
      'IMPLEMENTED': 'مُنفَّذ',
    };
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('مراجعة الاقتراح', style: AppText.h3),
              const SizedBox(height: 4),
              Text(k['title'] ?? '--', style: AppText.body, textDirection: TextDirection.rtl),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(
                  value: status, isExpanded: true, underline: const SizedBox(),
                  items: statuses.entries
                      .map((e) => DropdownMenuItem(value: e.key,
                          child: Text(e.value, textDirection: TextDirection.rtl)))
                      .toList(),
                  onChanged: (v) => ss(() => status = v!),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'ملاحظات الإدارة',
                  filled: true, fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ApiService.patch(
                          '/worker-tools/admin/kaizen/${k['id']}/review',
                          data: {
                            'status': status,
                            if (notesCtrl.text.isNotEmpty) 'adminNotes': notesCtrl.text,
                          });
                      _loadKaizen();
                    } catch (_) {}
                  },
                  child: const Text('حفظ',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Color _kaizenColor(String? s) {
    switch (s) {
      case 'PENDING':      return AppColors.neonGold;
      case 'UNDER_REVIEW': return AppColors.neonCyan;
      case 'APPROVED':     return AppColors.neonGreen;
      case 'REJECTED':     return AppColors.neonRed;
      case 'IMPLEMENTED':  return AppColors.neonPurple;
      default:             return AppColors.textSecondary;
    }
  }

  String _kaizenLabel(String? s) {
    switch (s) {
      case 'PENDING':      return 'معلق';
      case 'UNDER_REVIEW': return 'قيد المراجعة';
      case 'APPROVED':     return 'موافق';
      case 'REJECTED':     return 'مرفوض';
      case 'IMPLEMENTED':  return 'مُنفَّذ';
      default:             return s ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'سجلات العمال'),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'نظرة عامة'),
              Tab(text: 'تنبيهات الآلات'),
              Tab(text: 'اقتراحات كايزن'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_buildWorkers(), _buildAlerts(), _buildKaizen()],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildWorkers() {
    return _loadingWorkers
        ? const LoadingWidget()
        : _workers.isEmpty
            ? const Center(child: Text('لا توجد سجلات', textDirection: TextDirection.rtl))
            : RefreshIndicator(
                onRefresh: _loadWorkers,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _workers.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final w = _workers[i];
                    return GlassCard(
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.neonOrange.withValues(alpha: 0.2),
                            child: Text(
                              (w['name'] ?? w['user']?['name'] ?? '?')
                                  .toString()
                                  .isNotEmpty
                                  ? (w['name'] ?? w['user']?['name'] ?? '?')
                                      .toString()[0]
                                  : '?',
                              style: AppText.h3.copyWith(color: AppColors.neonOrange),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w['name'] ?? w['user']?['name'] ?? '--',
                                    style: AppText.h3, textDirection: TextDirection.rtl),
                                Text('إنتاج اليوم: ${w['todayProduction'] ?? '--'}',
                                    style: AppText.caption, textDirection: TextDirection.rtl),
                                Text('الحضور: ${w['attendanceRate'] ?? '--'}',
                                    style: AppText.caption, textDirection: TextDirection.rtl),
                              ],
                            ),
                          ),
                          Text('${w['totalProduction'] ?? '--'}',
                              style: AppText.h2.copyWith(color: AppColors.neonGreen)),
                        ],
                      ),
                    );
                  },
                ),
              );
  }

  Widget _buildAlerts() {
    return _loadingAlerts
        ? const LoadingWidget()
        : _alerts.isEmpty
            ? const Center(child: Text('لا توجد تنبيهات', textDirection: TextDirection.rtl))
            : RefreshIndicator(
                onRefresh: _loadAlerts,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alerts.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = _alerts[i];
                    final resolved = a['isResolved'] == true;
                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(a['machine']?['name'] ?? 'آلة غير محددة',
                                  style: AppText.h3, textDirection: TextDirection.rtl),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: (resolved
                                            ? AppColors.neonGreen
                                            : AppColors.neonRed)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  resolved ? 'حُل' : 'غير محلول',
                                  style: AppText.label.copyWith(
                                      color: resolved
                                          ? AppColors.neonGreen
                                          : AppColors.neonRed),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('العامل: ${a['worker']?['fullName'] ?? '--'}',
                              style: AppText.caption, textDirection: TextDirection.rtl),
                          Text('السبب: ${a['reason'] ?? '--'}',
                              style: AppText.body, textDirection: TextDirection.rtl),
                          if (!resolved)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _resolveAlert(a as Map<String, dynamic>),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.neonGreen),
                                  child: const Text('حل التنبيه',
                                      style: TextStyle(fontFamily: 'Cairo')),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
  }

  Widget _buildKaizen() {
    return _loadingKaizen
        ? const LoadingWidget()
        : _kaizen.isEmpty
            ? const Center(child: Text('لا توجد اقتراحات', textDirection: TextDirection.rtl))
            : RefreshIndicator(
                onRefresh: _loadKaizen,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _kaizen.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final k = _kaizen[i];
                    final status = k['status'] as String?;
                    final color = _kaizenColor(status);
                    return GestureDetector(
                      onTap: () => _reviewKaizen(k as Map<String, dynamic>),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(k['title'] ?? '--',
                                      style: AppText.h3,
                                      textDirection: TextDirection.rtl),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(_kaizenLabel(status),
                                      style: AppText.label.copyWith(color: color)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(k['description'] ?? '--',
                                style: AppText.body,
                                textDirection: TextDirection.rtl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            Text('العامل: ${k['worker']?['fullName'] ?? '--'}',
                                style: AppText.caption, textDirection: TextDirection.rtl),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}
