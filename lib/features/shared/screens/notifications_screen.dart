import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/notifications');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['notifications'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _markRead(String id) async {
    try {
      await ApiService.patch('/notifications/$id/read');
      setState(() {
        final idx = _items.indexWhere((n) => n['id']?.toString() == id);
        if (idx != -1) _items[idx]['isRead'] = true;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.patch('/notifications/read-all');
      setState(() {
        for (final n in _items) { n['isRead'] = true; }
      });
    } catch (_) {}
  }

  IconData _notifIcon(String? type) {
    switch (type) {
      case 'MAINTENANCE': return Icons.build_outlined;
      case 'QUALITY':     return Icons.verified_outlined;
      case 'PRODUCTION':  return Icons.inventory_2_outlined;
      case 'ATTENDANCE':  return Icons.fingerprint;
      case 'PAYROLL':     return Icons.payments_outlined;
      default:            return Icons.notifications_outlined;
    }
  }

  Color _notifColor(String? type) {
    switch (type) {
      case 'MAINTENANCE': return AppColors.neonGold;
      case 'QUALITY':     return AppColors.neonGreen;
      case 'PRODUCTION':  return AppColors.neonCyan;
      case 'ATTENDANCE':  return AppColors.neonOrange;
      case 'PAYROLL':     return AppColors.neonPurple;
      default:            return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => n['isRead'] != true).length;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AiBackground(
        child: Column(children: [
          AiAppBar(
            title: 'الإشعارات${unread > 0 ? ' ($unread)' : ''}',
            actions: [
              if (unread > 0)
                TextButton(
                  onPressed: _markAllRead,
                  child: Text('قراءة الكل',
                      style: AppText.caption.copyWith(color: AppColors.neonPurple)),
                ),
            ],
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(
                        message: 'لا توجد إشعارات',
                        icon: Icons.notifications_none_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            final isRead = n['isRead'] == true;
                            final type = n['type'] as String?;
                            final color = _notifColor(type);
                            return GestureDetector(
                              onTap: () => !isRead ? _markRead(n['id']?.toString() ?? '') : null,
                              child: GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: isRead ? 0.08 : 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_notifIcon(type), color: color, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(n['title'] ?? '--',
                                              style: AppText.h3.copyWith(
                                                  color: isRead ? AppColors.textSecondary : AppColors.textPrimary),
                                              textDirection: TextDirection.rtl),
                                          const SizedBox(height: 2),
                                          Text(n['body'] ?? n['message'] ?? '--',
                                              style: AppText.caption,
                                              textDirection: TextDirection.rtl,
                                              maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(n['createdAt']?.toString().substring(0, 16) ?? '--',
                                              style: AppText.label),
                                        ],
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8, height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.neonPurple,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
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
