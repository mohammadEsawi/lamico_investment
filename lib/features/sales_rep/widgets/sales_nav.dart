import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/responsive.dart';

class SalesNav extends StatelessWidget {
  final int selectedIndex;
  const SalesNav({required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return const SizedBox.shrink();
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/sales'); break;
          case 1: context.go('/sales/customers'); break;
          case 2: context.go('/sales/quotations'); break;
          case 3: context.go('/sales/visits'); break;
          case 4: context.go('/sales/targets'); break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: Colors.white),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people, color: Colors.white),
          label: 'العملاء',
        ),
        NavigationDestination(
          icon: Icon(Icons.request_quote_outlined),
          selectedIcon: Icon(Icons.request_quote, color: Colors.white),
          label: 'العروض',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_car_outlined),
          selectedIcon: Icon(Icons.directions_car, color: Colors.white),
          label: 'الزيارات',
        ),
        NavigationDestination(
          icon: Icon(Icons.flag_outlined),
          selectedIcon: Icon(Icons.flag, color: Colors.white),
          label: 'الأهداف',
        ),
      ],
    );
  }
}

class SalesMoreMenu extends StatelessWidget {
  const SalesMoreMenu({super.key});

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
        _item('/sales/sales', 'المبيعات', Icons.point_of_sale_outlined, AppColors.neonGold),
        _item('/inventory', 'المخزن', Icons.inventory_2_outlined, AppColors.neonCyan),
        _item('/chat', 'الدردشة', Icons.chat_bubble_outline, AppColors.neonCyan),
        _item('/profile', 'الملف الشخصي', Icons.person_outline, AppColors.neonPurple),
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
            Text(label, style: const TextStyle(fontFamily: 'Cairo')),
          ],
        ),
      );
}
