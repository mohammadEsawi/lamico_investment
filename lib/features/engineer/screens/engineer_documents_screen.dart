import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerDocumentsScreen extends StatefulWidget {
  const EngineerDocumentsScreen({super.key});
  @override
  State<EngineerDocumentsScreen> createState() => _EngineerDocumentsScreenState();
}

class _EngineerDocumentsScreenState extends State<EngineerDocumentsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/tech-document/');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['documents'] ?? data['data'] ?? []);
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
          AiAppBar(title: 'الوثائق التقنية'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد وثائق تقنية', icon: Icons.description_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final doc = _items[i];
                            return GlassCard(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonCyan.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.description_outlined,
                                        color: AppColors.neonCyan),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(doc['title'] ?? doc['name'] ?? '--',
                                            style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text(doc['category'] ?? doc['type'] ?? '--',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                        Text(doc['createdAt']?.toString().substring(0, 10) ?? '--',
                                            style: AppText.label),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.download_outlined,
                                      color: AppColors.neonCyan, size: 20),
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
