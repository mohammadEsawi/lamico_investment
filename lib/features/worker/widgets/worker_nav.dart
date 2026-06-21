import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/services/auth_service.dart';

class WorkerNav extends StatelessWidget {
  final int selectedIndex;
  const WorkerNav({required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/worker'); break;
          case 1: context.go('/worker/production'); break;
          case 2: context.go('/worker/attendance'); break;
          case 3: context.go('/worker/tools'); break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: Colors.white),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2, color: Colors.white),
          label: 'الإنتاج',
        ),
        NavigationDestination(
          icon: Icon(Icons.fingerprint),
          selectedIcon: Icon(Icons.fingerprint, color: Colors.white),
          label: 'الحضور',
        ),
        NavigationDestination(
          icon: Icon(Icons.handyman_outlined),
          selectedIcon: Icon(Icons.handyman, color: Colors.white),
          label: 'أدوات',
        ),
      ],
    );
  }
}

class WorkerMoreMenu extends StatelessWidget {
  const WorkerMoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: Theme.of(context).cardColor,
      onSelected: (route) async {
        if (route == '/logout') {
          await AuthService.logout();
          if (context.mounted) context.go('/login');
        } else {
          context.push(route);
        }
      },
      itemBuilder: (_) => [
        _item('/worker/payroll', 'راتبي', Icons.payments_outlined, AppColors.neonGreen),
        _item('/inventory', 'المخزن', Icons.inventory_2_outlined, AppColors.neonCyan),
        _item('/chat', 'الدردشة', Icons.chat_bubble_outline, AppColors.neonCyan),
        _item('/profile', 'الملف الشخصي', Icons.person_outline, AppColors.textSecondary),
        _item('/logout', 'تسجيل الخروج', Icons.logout, AppColors.neonRed),
      ],
    );
  }

  PopupMenuItem<String> _item(String value, String label, IconData icon, Color color) =>
      PopupMenuItem(
        value: value,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: AppText.body.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      );
}
