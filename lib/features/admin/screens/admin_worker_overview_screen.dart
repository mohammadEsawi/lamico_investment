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

class _AdminWorkerOverviewScreenState extends State<AdminWorkerOverviewScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/worker-tools/admin/overview');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['workers'] ?? data['data'] ?? []);
        _loading = false;
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
          AiAppBar(title: 'سجلات العمال'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(
                        message: 'لا توجد سجلات عمال',
                        icon: Icons.people_alt_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final w = _items[i];
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.neonOrange.withValues(alpha: 0.2),
                                    child: Text(
                                      (w['name'] ?? w['user']?['name'] ?? '?').toString().isNotEmpty
                                          ? (w['name'] ?? w['user']?['name'] ?? '?').toString()[0]
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
                                            style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text('إنتاج اليوم: ${w['todayProduction'] ?? '--'}',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                        Text('الحضور: ${w['attendanceRate'] ?? '--'}',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                      ],
                                    ),
                                  ),
                                  ShaderMask(
                                    shaderCallback: (b) => AppColors.successGrad.createShader(b),
                                    child: Text(
                                      '${w['totalProduction'] ?? '--'}',
                                      style: AppText.h2.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}
