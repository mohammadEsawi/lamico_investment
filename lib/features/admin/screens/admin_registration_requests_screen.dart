import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminRegistrationRequestsScreen extends StatefulWidget {
  const AdminRegistrationRequestsScreen({super.key});
  @override
  State<AdminRegistrationRequestsScreen> createState() =>
      _AdminRegistrationRequestsScreenState();
}

class _AdminRegistrationRequestsScreenState
    extends State<AdminRegistrationRequestsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/registration-requests');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['requests'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _approve(String id) async {
    try {
      await ApiService.patch('/registration-requests/$id/approve');
      _load();
    } catch (_) {}
  }

  Future<void> _reject(String id) async {
    try {
      await ApiService.patch('/registration-requests/$id/reject');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'طلبات التسجيل'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(
                        message: 'لا توجد طلبات تسجيل',
                        icon: Icons.how_to_reg_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _items[i];
                            final status = r['status'] as String? ?? 'PENDING';
                            final isPending = status == 'PENDING';
                            return GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r['fullName'] ?? '--',
                                              style: AppText.h3,
                                              textDirection: TextDirection.rtl),
                                          Text(r['email'] ?? '--',
                                              style: AppText.caption,
                                              textDirection: TextDirection.rtl),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPending
                                              ? AppColors.neonGold.withValues(alpha: 0.15)
                                              : status == 'APPROVED'
                                                  ? AppColors.neonGreen.withValues(alpha: 0.15)
                                                  : AppColors.neonRed.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isPending ? 'قيد الانتظار'
                                              : status == 'APPROVED' ? 'موافق عليه' : 'مرفوض',
                                          style: AppText.label.copyWith(
                                            color: isPending ? AppColors.neonGold
                                                : status == 'APPROVED'
                                                    ? AppColors.neonGreen : AppColors.neonRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (r['message'] != null && r['message'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text('ملاحظات: ${r['message']}',
                                        style: AppText.caption,
                                        textDirection: TextDirection.rtl),
                                  ],
                                  if (isPending) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.neonGreen,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () => _approve(r['id'] ?? ''),
                                            child: const Text('موافقة',
                                                style: TextStyle(fontFamily: 'Cairo')),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.neonRed,
                                              side: const BorderSide(color: AppColors.neonRed),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () => _reject(r['id'] ?? ''),
                                            child: const Text('رفض',
                                                style: TextStyle(fontFamily: 'Cairo')),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
