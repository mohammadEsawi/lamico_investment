import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../widgets/worker_nav.dart';

class WorkerToolsScreen extends StatelessWidget {
  const WorkerToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool('عدادات الكهرباء', Icons.bolt_outlined, AppColors.neonGold,
          'تسجيل قراءات عدادات الكهرباء', '/worker/electricity', navigate: true),
      _Tool('توقفات الآلات', Icons.pause_circle_outline, AppColors.neonRed,
          'سجّل توقفات الآلات', '/worker/machine-stops'),
      _Tool('قوائم التفتيش', Icons.checklist_outlined, AppColors.neonCyan,
          'قوائم تفتيش يومية', '/worker/checklists'),
      _Tool('هدر المواد', Icons.delete_outline, AppColors.neonOrange,
          'تسجيل هدر المواد', '/worker/waste'),
      _Tool('الأهداف اليومية', Icons.flag_outlined, AppColors.neonGreen,
          'عرض وتتبع الأهداف', '/worker/targets'),
      _Tool('مقترحات كايزن', Icons.lightbulb_outline, AppColors.neonGold,
          'إرسال مقترحات تحسين', '/worker/kaizen'),
      _Tool('مشاكل الجودة', Icons.warning_amber_outlined, AppColors.neonPurple,
          'الإبلاغ عن مشاكل الجودة', '/worker/quality-issues'),
      _Tool('التوقفات الصغيرة', Icons.timer_off_outlined, AppColors.neonBlue,
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
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final t = tools[i];
                return GestureDetector(
                  onTap: () => t.navigate ? context.push(t.route) : _handleTool(context, t.route),
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

  void _handleTool(BuildContext context, String route) {
    _showToolSheet(context, route);
  }

  void _showToolSheet(BuildContext context, String route) {
    final labelMap = {
      '/worker/machine-stops':  'توقفات الآلات',
      '/worker/checklists':     'قوائم التفتيش',
      '/worker/waste':          'هدر المواد',
      '/worker/targets':        'الأهداف اليومية',
      '/worker/kaizen':         'مقترحات كايزن',
      '/worker/quality-issues': 'مشاكل الجودة',
      '/worker/micro-stops':    'التوقفات الصغيرة',
    };
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labelMap[route] ?? 'تسجيل',
                style: AppText.h2, textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: TextField(
                controller: notesCtrl,
                textAlign: TextAlign.right,
                maxLines: 3,
                style: AppText.body.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'أدخل التفاصيل...',
                  hintStyle: AppText.body,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    const endpointMap = {
                      '/worker/machine-stops':  '/worker-tools/machine-stop-alerts',
                      '/worker/checklists':     '/worker-tools/shift-checklists',
                      '/worker/waste':          '/worker-tools/material-waste',
                      '/worker/targets':        '/worker-tools/daily-targets',
                      '/worker/kaizen':         '/worker-tools/kaizen',
                      '/worker/quality-issues': '/worker-tools/quality-issues',
                      '/worker/micro-stops':    '/worker-tools/micro-stops',
                    };
                    final endpoint = endpointMap[route] ?? route;
                    await ApiService.post(endpoint, data: {'notes': notesCtrl.text.trim()});
                  } catch (_) {}
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
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
