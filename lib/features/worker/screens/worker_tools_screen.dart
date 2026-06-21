import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/worker_nav.dart';

class WorkerToolsScreen extends StatelessWidget {
  const WorkerToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool('عدادات الكهرباء',  Icons.bolt_outlined,          AppColors.neonGold,
          'تسجيل قراءات عدادات الكهرباء', '/worker/electricity', navigate: true),
      _Tool('توقفات الآلات',    Icons.pause_circle_outline,    AppColors.neonRed,
          'سجّل توقفات الآلات', '/worker/machine-stops'),
      _Tool('قوائم التفتيش',    Icons.checklist_outlined,      AppColors.neonCyan,
          'قوائم تفتيش يومية',  '/worker/checklists'),
      _Tool('هدر المواد',       Icons.delete_outline,          AppColors.neonOrange,
          'تسجيل هدر المواد',   '/worker/waste'),
      _Tool('الأهداف اليومية',  Icons.flag_outlined,           AppColors.neonGreen,
          'عرض وتتبع الأهداف',  '/worker/targets'),
      _Tool('مقترحات كايزن',   Icons.lightbulb_outline,       AppColors.neonGold,
          'إرسال مقترحات تحسين', '/worker/kaizen'),
      _Tool('مشاكل الجودة',    Icons.warning_amber_outlined,  AppColors.neonPurple,
          'الإبلاغ عن مشاكل الجودة', '/worker/quality-issues'),
      _Tool('التوقفات الصغيرة', Icons.timer_off_outlined,     AppColors.neonBlue,
          'تسجيل التوقفات الصغيرة', '/worker/micro-stops'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const WorkerNav(selectedIndex: 3),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الأدوات'),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tools.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final t = tools[i];
                return GestureDetector(
                  onTap: () => t.navigate
                      ? context.push(t.route)
                      : _showToolSheet(context, t),
                  child: GlassCard(
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: t.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(t.icon, color: t.color, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.label, style: AppText.h3,
                                  textDirection: TextDirection.rtl),
                              Text(t.subtitle, style: AppText.caption,
                                  textDirection: TextDirection.rtl),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_back_ios, color: t.color, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _showToolSheet(BuildContext context, _Tool tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ToolSheet(tool: tool),
    );
  }
}

class _ToolSheet extends StatefulWidget {
  final _Tool tool;
  const _ToolSheet({required this.tool});

  @override
  State<_ToolSheet> createState() => _ToolSheetState();
}

class _ToolSheetState extends State<_ToolSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _notesCtrl = TextEditingController();
  List<dynamic> _history = [];
  bool _loadingHistory = false;

  static const _endpointMap = {
    '/worker/machine-stops':  '/worker-tools/machine-stop-alerts',
    '/worker/checklists':     '/worker-tools/shift-checklists',
    '/worker/waste':          '/worker-tools/material-waste',
    '/worker/targets':        '/worker-tools/daily-targets',
    '/worker/kaizen':         '/worker-tools/kaizen',
    '/worker/quality-issues': '/worker-tools/quality-issues',
    '/worker/micro-stops':    '/worker-tools/micro-stops',
  };

  static const _historyEndpointMap = {
    '/worker/machine-stops':  '/worker-tools/machine-stop-alerts/mine',
    '/worker/checklists':     '/worker-tools/shift-checklists/mine',
    '/worker/waste':          '/worker-tools/material-waste/mine',
    '/worker/targets':        '/worker-tools/daily-targets/mine',
    '/worker/kaizen':         '/worker-tools/kaizen/mine',
    '/worker/quality-issues': '/worker-tools/quality-issues/mine',
    '/worker/micro-stops':    '/worker-tools/micro-stops/mine',
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() { if (_tab.index == 1) _loadHistory(); });
  }

  @override
  void dispose() {
    _tab.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final path = _historyEndpointMap[widget.tool.route];
      if (path == null) { setState(() => _loadingHistory = false); return; }
      final res = await ApiService.get(path);
      final data = res.data;
      setState(() {
        _history = data is List ? data : (data['data'] ?? data['items'] ?? []);
        _loadingHistory = false;
      });
    } catch (_) { setState(() => _loadingHistory = false); }
  }

  Future<void> _submit() async {
    final endpoint = _endpointMap[widget.tool.route];
    if (endpoint == null) return;
    try {
      await ApiService.post(endpoint, data: {'notes': _notesCtrl.text.trim()});
      _notesCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم الإرسال بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.neonGreen,
        ));
        if (_tab.index == 1) _loadHistory();
      }
    } catch (_) {}
  }

  Future<void> _deleteEntry(dynamic item) async {
    final id = item['id'];
    if (id == null) return;
    final featureMap = {
      '/worker/machine-stops':  'machine-stop-alerts',
      '/worker/checklists':     'shift-checklists',
      '/worker/waste':          'material-waste',
      '/worker/targets':        'daily-targets',
      '/worker/kaizen':         'kaizen',
      '/worker/quality-issues': 'quality-issues',
      '/worker/micro-stops':    'micro-stops',
    };
    final feature = featureMap[widget.tool.route];
    if (feature == null) return;
    try {
      await ApiService.delete('/worker-tools/entries/$feature/$id');
      _loadHistory();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => Column(children: [
        Container(
          color: AppColors.bgCard,
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tab,
              indicatorColor: widget.tool.color,
              labelColor: widget.tool.color,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              tabs: [
                Tab(icon: Icon(Icons.add_circle_outline, color: widget.tool.color), text: 'تسجيل'),
                Tab(icon: Icon(Icons.history, color: widget.tool.color), text: 'السجلات'),
              ],
            ),
          ]),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              // Register tab
              SingleChildScrollView(
                controller: scroll,
                padding: EdgeInsets.only(
                    left: 24, right: 24, top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24),
                child: Column(children: [
                  Text(widget.tool.label, style: AppText.h2,
                      textDirection: TextDirection.rtl),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: widget.tool.color.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _notesCtrl,
                      textAlign: TextAlign.right,
                      maxLines: 4,
                      style: AppText.body.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'أدخل التفاصيل...',
                        hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.tool.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submit,
                      child: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                ]),
              ),
              // History tab
              _loadingHistory
                  ? const LoadingWidget()
                  : _history.isEmpty
                      ? const EmptyStateWidget(message: 'لا توجد سجلات', icon: Icons.history)
                      : ListView.separated(
                          controller: scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final item = _history[i];
                            return GestureDetector(
                              onLongPress: () => _deleteEntry(item),
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    const Icon(Icons.circle, size: 6, color: AppColors.neonOrange),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['notes'] ?? item['description'] ?? '--',
                                            style: AppText.body,
                                            textDirection: TextDirection.rtl,
                                          ),
                                          Text(
                                            item['createdAt']?.toString().substring(0, 10) ?? '--',
                                            style: AppText.label,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Tool {
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String route;
  final bool navigate;
  const _Tool(this.label, this.icon, this.color, this.subtitle, this.route,
      {this.navigate = false});
}
