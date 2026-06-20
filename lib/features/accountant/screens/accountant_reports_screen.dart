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

class _AccountantReportsScreenState extends State<AccountantReportsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/financial-reports');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['reports'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AccountantNav(selectedIndex: 2),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'التقارير المالية'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد تقارير مالية', icon: Icons.bar_chart_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _items[i];
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
                                  const Icon(Icons.download_outlined,
                                      color: AppColors.neonPurple, size: 20),
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
