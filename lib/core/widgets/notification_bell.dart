import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _fetchCount();
    SocketService.onUnreadCountUpdate((_) {
      if (mounted) _fetchCount();
    });
  }

  @override
  void dispose() {
    SocketService.offUnreadCountUpdate();
    super.dispose();
  }

  Future<void> _fetchCount() async {
    try {
      final res  = await ApiService.get('/notifications/unread-count');
      final data = res.data;
      if (!mounted) return;
      final count = (data['count'] ?? data['unreadCount'] ?? data['total'] ?? 0) as num;
      setState(() => _unread = count.toInt());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
          onPressed: () async {
            await context.push('/notifications');
            if (mounted) _fetchCount();
          },
        ),
        if (_unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.neonRed,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _unread > 99 ? '99+' : '$_unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
