import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/services/auth_service.dart';

class EngineerNav extends StatelessWidget {
  final int selectedIndex;
  const EngineerNav({required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/engineer'); break;
          case 1: context.go('/engineer/maintenance'); break;
          case 2: context.go('/engineer/quality'); break;
          case 3: context.go('/engineer/machines'); break;
          case 4: _showMore(context); break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.neonCyan),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build, color: AppColors.neonCyan),
          label: 'الصيانة',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_outlined),
          selectedIcon: Icon(Icons.verified, color: AppColors.neonCyan),
          label: 'الجودة',
        ),
        NavigationDestination(
          icon: Icon(Icons.precision_manufacturing_outlined),
          selectedIcon: Icon(Icons.precision_manufacturing, color: AppColors.neonCyan),
          label: 'المعدات',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz, color: AppColors.neonCyan),
          label: 'المزيد',
        ),
      ],
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _tile(context, 'قطع الغيار', Icons.settings_outlined, AppColors.neonGold, '/engineer/spare-parts'),
            _tile(context, 'الجرد', Icons.inventory_outlined, AppColors.neonOrange, '/engineer/inventory'),
            _tile(context, 'الوثائق التقنية', Icons.description_outlined, AppColors.neonCyan, '/engineer/documents'),
            _tile(context, 'الدردشة', Icons.chat_bubble_outline, AppColors.neonPurple, '/chat'),
            _tile(context, 'الملف الشخصي', Icons.person_outline, AppColors.textSecondary, '/profile'),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.neonRed),
              title: Text('تسجيل الخروج',
                  style: AppText.body.copyWith(color: AppColors.neonRed)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService.logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext ctx, String label, IconData icon, Color color, String route) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppText.body.copyWith(color: AppColors.textPrimary)),
      onTap: () { Navigator.pop(ctx); ctx.go(route); },
    );
  }
}
