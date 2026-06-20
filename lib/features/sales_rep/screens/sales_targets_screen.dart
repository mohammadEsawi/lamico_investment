import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/sales_nav.dart';

class SalesTargetsScreen extends StatefulWidget {
  const SalesTargetsScreen({super.key});
  @override
  State<SalesTargetsScreen> createState() => _SalesTargetsScreenState();
}

class _SalesTargetsScreenState extends State<SalesTargetsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/sales-rep/targets');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['targets'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const SalesNav(selectedIndex: 4),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'أهداف المبيعات'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد أهداف محددة', icon: Icons.flag_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final t = _items[i];
                            final target   = (t['targetAmount'] ?? t['target'] ?? 0) as num;
                            final achieved = (t['achievedAmount'] ?? t['achieved'] ?? 0) as num;
                            final pct = target > 0 ? (achieved / target).clamp(0.0, 1.0) : 0.0;
                            return GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(t['period'] ?? t['month'] ?? '--',
                                          style: AppText.h3, textDirection: TextDirection.rtl),
                                      Text('${(pct * 100).toStringAsFixed(0)}%',
                                          style: AppText.h3.copyWith(
                                              color: pct >= 1.0 ? AppColors.neonGreen : AppColors.neonGold)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct.toDouble(),
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        pct >= 1.0 ? AppColors.neonGreen : AppColors.neonGold,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('الهدف: $target ج.م', style: AppText.caption),
                                      Text('المحقق: $achieved ج.م', style: AppText.caption),
                                    ],
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
