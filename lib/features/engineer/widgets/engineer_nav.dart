import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
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
          selectedIcon: Icon(Icons.home, color: AppColors.neonOrange),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build, color: AppColors.neonOrange),
          label: 'الصيانة',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_outlined),
          selectedIcon: Icon(Icons.verified, color: AppColors.neonOrange),
          label: 'الجودة',
        ),
        NavigationDestination(
          icon: Icon(Icons.precision_manufacturing_outlined),
          selectedIcon: Icon(Icons.precision_manufacturing, color: AppColors.neonOrange),
          label: 'المعدات',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz, color: AppColors.neonOrange),
          label: 'المزيد',
        ),
      ],
    );
  }

  void _showMore(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _tile(context, 'تسجيل الكهرباء', Icons.bolt_outlined, AppColors.neonGold, '/engineer/electricity'),
            _tile(context, 'تسجيل الإنتاج', Icons.factory_outlined, AppColors.neonOrange, '/engineer/production'),
            _tile(context, 'الحضور', Icons.fingerprint, AppColors.neonGreen, '/engineer/attendance'),
            _tile(context, 'المخزن', Icons.inventory_2_outlined, AppColors.neonCyan, '/inventory'),
            _tile(context, 'قطع الغيار', Icons.settings_outlined, AppColors.neonGold, '/engineer/spare-parts'),
            _tile(context, 'طلبات قطع الغيار', Icons.shopping_cart_outlined, AppColors.neonOrange, '/engineer/spare-part-requests'),
            _tile(context, 'جدول الصيانة', Icons.calendar_month_outlined, AppColors.neonPurple, '/engineer/maintenance-schedule'),
            _tile(context, 'صحة الآلات', Icons.monitor_heart_outlined, AppColors.neonCyan, '/engineer/machine-health'),
            _tile(context, 'تكاليف الصيانة', Icons.receipt_long_outlined, AppColors.neonOrange, '/engineer/maintenance-costs'),
            _tile(context, 'تنبيهات المواد', Icons.warning_amber_outlined, AppColors.neonRed, '/engineer/raw-material-alerts'),
            _tile(context, 'الجرد', Icons.inventory_outlined, AppColors.neonOrange, '/engineer/inventory'),
            _tile(context, 'الوثائق التقنية', Icons.description_outlined, AppColors.neonCyan, '/engineer/documents'),
            _tile(context, 'قراءات الآلات الداعمة', Icons.speed_outlined, AppColors.neonOrange, '/engineer/support-machine'),
            _tile(context, 'الدردشة', Icons.chat_bubble_outline, AppColors.neonPurple, '/chat'),
            _tile(context, 'الملف الشخصي', Icons.person_outline, c.textSecondary, '/profile'),
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
    final c = ctx.colors;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppText.body.copyWith(color: c.textPrimary)),
      onTap: () { Navigator.pop(ctx); ctx.go(route); },
    );
  }
}
