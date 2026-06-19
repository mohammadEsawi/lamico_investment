import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/services/auth_service.dart';

class AdminNav extends StatelessWidget {
  final int selectedIndex;
  const AdminNav({required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/admin'); break;
          case 1: context.go('/admin/analytics'); break;
          case 2: context.go('/admin/users'); break;
          case 3: context.go('/admin/machines'); break;
          case 4: _showMore(context); break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.neonPurple),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: AppColors.neonPurple),
          label: 'التحليلات',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people, color: AppColors.neonPurple),
          label: 'المستخدمون',
        ),
        NavigationDestination(
          icon: Icon(Icons.precision_manufacturing_outlined),
          selectedIcon: Icon(Icons.precision_manufacturing, color: AppColors.neonPurple),
          label: 'الآلات',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz, color: AppColors.neonPurple),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _tile(context, 'الورديات', Icons.schedule, AppColors.neonPurple, '/admin/shifts'),
            _tile(context, 'الحضور', Icons.fingerprint, AppColors.neonCyan, '/admin/attendance'),
            _tile(context, 'الرواتب', Icons.payments_outlined, AppColors.neonGreen, '/admin/payroll'),
            _tile(context, 'طلبات التسجيل', Icons.how_to_reg_outlined, AppColors.neonGold, '/admin/requests'),
            _tile(context, 'سجلات العمال', Icons.people_alt_outlined, AppColors.neonOrange, '/admin/workers'),
            _tile(context, 'الإعدادات', Icons.settings_outlined, AppColors.textSecondary, '/admin/settings'),
            _tile(context, 'سجلات التدقيق', Icons.history, AppColors.textSecondary, '/admin/audit'),
            _tile(context, 'الدردشة', Icons.chat_bubble_outline, AppColors.neonCyan, '/chat'),
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
