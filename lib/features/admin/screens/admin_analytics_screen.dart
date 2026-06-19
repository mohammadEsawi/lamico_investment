import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _selectedDays = 7;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/dashboard/charts', params: {'days': _selectedDays});
      setState(() { _data = res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 1),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'التحليلات'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dayChip('اليوم', 1),
                const SizedBox(width: 8),
                _dayChip('7 أيام', 7),
                const SizedBox(width: 8),
                _dayChip('30 يوم', 30),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _data == null
                    ? const EmptyStateWidget(message: 'لا توجد بيانات تحليلية')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(textDirection: TextDirection.rtl, children: [
                                    ShaderMask(
                                      shaderCallback: (b) => AppColors.primaryGrad.createShader(b),
                                      child: const Icon(Icons.bar_chart, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('الإنتاج اليومي', style: AppText.h3),
                                  ]),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 180,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.bar_chart, size: 48, color: AppColors.neonPurple),
                                          const SizedBox(height: 8),
                                          Text(
                                            'إجمالي: ${_data?['totalProduction'] ?? '--'} كرتون',
                                            style: AppText.body,
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(textDirection: TextDirection.rtl, children: [
                                    const Icon(Icons.trending_up, color: AppColors.neonGreen, size: 20),
                                    const SizedBox(width: 8),
                                    Text('ملخص الأداء', style: AppText.h3),
                                  ]),
                                  const SizedBox(height: 16),
                                  _statRow('متوسط الإنتاج اليومي',
                                      '${_data?['avgDailyProduction'] ?? '--'}'),
                                  _statRow('أعلى يوم إنتاجاً',
                                      '${_data?['bestDay'] ?? '--'}'),
                                  _statRow('نسبة تشغيل الآلات',
                                      '${_data?['machineUptime'] ?? '--'}%'),
                                  _statRow('عدد أوامر الصيانة',
                                      '${_data?['maintenanceCount'] ?? '--'}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(textDirection: TextDirection.rtl, children: [
                                    const Icon(Icons.people, color: AppColors.neonCyan, size: 20),
                                    const SizedBox(width: 8),
                                    Text('الحضور والغياب', style: AppText.h3),
                                  ]),
                                  const SizedBox(height: 16),
                                  _statRow('إجمالي أيام الحضور',
                                      '${_data?['totalAttendance'] ?? '--'}'),
                                  _statRow('إجمالي أيام الغياب',
                                      '${_data?['totalAbsence'] ?? '--'}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _dayChip(String label, int days) {
    final selected = _selectedDays == days;
    return GestureDetector(
      onTap: () { setState(() => _selectedDays = days); _load(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGrad : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(label,
            style: AppText.caption.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body, textDirection: TextDirection.rtl),
          Text(value, style: AppText.h3.copyWith(color: AppColors.neonPurple)),
        ],
      ),
    );
  }
}
