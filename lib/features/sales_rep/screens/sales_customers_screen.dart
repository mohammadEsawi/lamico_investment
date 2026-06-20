import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/sales_nav.dart';

class SalesCustomersScreen extends StatefulWidget {
  const SalesCustomersScreen({super.key});
  @override
  State<SalesCustomersScreen> createState() => _SalesCustomersScreenState();
}

class _SalesCustomersScreenState extends State<SalesCustomersScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/sales-rep/customers');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['customers'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const SalesNav(selectedIndex: 1),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'العملاء'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا يوجد عملاء', icon: Icons.people_outline)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final c = _items[i];
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.neonGold.withValues(alpha: 0.2),
                                    child: Text(
                                      (c['name'] ?? '?').toString().isNotEmpty
                                          ? (c['name'] as String)[0] : '?',
                                      style: AppText.h3.copyWith(color: AppColors.neonGold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c['name'] ?? '--', style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text(c['phone'] ?? c['email'] ?? '--',
                                            style: AppText.caption, textDirection: TextDirection.rtl),
                                        Text(c['city'] ?? c['address'] ?? '--',
                                            style: AppText.label),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_left, color: AppColors.textMuted),
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
