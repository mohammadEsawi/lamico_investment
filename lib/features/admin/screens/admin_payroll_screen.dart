import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key});
  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  Map<String, dynamic>? _data;
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/payroll/admin/overview');
      final data = res.data;
      setState(() {
        if (data is Map) {
          _data = data as Map<String, dynamic>;
          _records = data['records'] ?? data['payrolls'] ?? [];
        } else if (data is List) {
          _records = data;
        }
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
          AiAppBar(title: 'الرواتب'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_data != null) ...[
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                            children: [
                              KpiCard(
                                label: 'إجمالي الرواتب',
                                value: '${_data!['totalSalaries'] ?? '--'}',
                                gradient: AppColors.primaryGrad,
                                icon: Icons.payments_outlined,
                              ),
                              KpiCard(
                                label: 'عدد الموظفين',
                                value: '${_data!['employeeCount'] ?? '--'}',
                                gradient: AppColors.successGrad,
                                icon: Icons.people_outline,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_records.isEmpty)
                          const EmptyStateWidget(
                              message: 'لا توجد سجلات رواتب',
                              icon: Icons.payments_outlined)
                        else
                          ...List.generate(_records.length, (i) {
                            final r = _records[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    const Icon(Icons.person_outline,
                                        color: AppColors.neonPurple),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r['user']?['name'] ?? r['employeeName'] ?? '--',
                                              style: AppText.h3,
                                              textDirection: TextDirection.rtl),
                                          Text(r['month'] ?? r['period'] ?? '--',
                                              style: AppText.caption,
                                              textDirection: TextDirection.rtl),
                                        ],
                                      ),
                                    ),
                                    ShaderMask(
                                      shaderCallback: (b) => AppColors.successGrad.createShader(b),
                                      child: Text(
                                        '${r['netSalary'] ?? r['amount'] ?? '--'} ج.م',
                                        style: AppText.h3.copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
