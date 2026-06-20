import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerSparePartsScreen extends StatefulWidget {
  const EngineerSparePartsScreen({super.key});
  @override
  State<EngineerSparePartsScreen> createState() => _EngineerSparePartsScreenState();
}

class _EngineerSparePartsScreenState extends State<EngineerSparePartsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/spare-parts/');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['parts'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'قطع الغيار'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد قطع غيار', icon: Icons.settings_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final p = _items[i];
                            final qty = p['quantity'] ?? p['stock'] ?? 0;
                            final lowStock = (qty is num) && qty < 5;
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.settings, color: AppColors.neonGold),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['name'] ?? '--', style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text(p['partNumber'] ?? p['code'] ?? '--',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('الكمية: $qty',
                                          style: AppText.body.copyWith(
                                              color: lowStock ? AppColors.neonRed : AppColors.neonGreen)),
                                      if (lowStock)
                                        Text('مخزون منخفض',
                                            style: AppText.label.copyWith(color: AppColors.neonRed)),
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
