import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/services/auth_service.dart';

class AccountantNav extends StatelessWidget {
  final int selectedIndex;
  const AccountantNav({required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/accountant'); break;
          case 1: context.go('/accountant/invoices'); break;
          case 2: context.go('/accountant/reports'); break;
          case 3: _showMore(context); break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.neonGreen),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: AppColors.neonGreen),
          label: 'الفواتير',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: AppColors.neonGreen),
          label: 'التقارير',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz, color: AppColors.neonGreen),
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
            _tile(context, 'مستحقات العملاء', Icons.people_outline, AppColors.neonCyan, '/accountant/receivables'),
            _tile(context, 'مستحقات الموردين', Icons.business_outlined, AppColors.neonOrange, '/accountant/payables'),
            _tile(context, 'الموردون', Icons.store_outlined, AppColors.neonGold, '/accountant/suppliers'),
            _tile(context, 'المصروفات', Icons.money_off_outlined, AppColors.neonRed, '/accountant/expenses'),
            _tile(context, 'خطة الميزانية', Icons.account_balance_outlined, AppColors.neonPurple, '/accountant/budget'),
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
