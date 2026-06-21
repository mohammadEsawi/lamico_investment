import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
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
          selectedIcon: Icon(Icons.home, color: AppColors.neonOrange),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: AppColors.neonOrange),
          label: 'التحليلات',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people, color: AppColors.neonOrange),
          label: 'المستخدمون',
        ),
        NavigationDestination(
          icon: Icon(Icons.precision_manufacturing_outlined),
          selectedIcon: Icon(Icons.precision_manufacturing, color: AppColors.neonOrange),
          label: 'الآلات',
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _tile(context, 'المخزن', Icons.inventory_2_outlined, AppColors.neonCyan, '/inventory'),
            _tile(context, 'الإنتاج', Icons.factory_outlined, AppColors.neonOrange, '/admin/production'),
            _tile(context, 'إدارة الكهرباء', Icons.bolt_outlined, AppColors.neonGold, '/admin/electricity'),
            _tile(context, 'الصيانة', Icons.build_outlined, AppColors.neonCyan, '/admin/maintenance'),
            _tile(context, 'صحة الآلات', Icons.monitor_heart_outlined, AppColors.neonGreen, '/admin/machine-health'),
            _tile(context, 'تكاليف الصيانة', Icons.receipt_long_outlined, AppColors.neonOrange, '/admin/maintenance-costs'),
            _tile(context, 'الأداء', Icons.trending_up_outlined, AppColors.neonPurple, '/admin/performance'),
            _tile(context, 'الذكاء الاصطناعي', Icons.auto_awesome_outlined, AppColors.neonCyan, '/admin/ai'),
            _tile(context, 'الورديات', Icons.schedule, AppColors.neonPurple, '/admin/shifts'),
            _tile(context, 'الحضور', Icons.fingerprint, AppColors.neonCyan, '/admin/attendance'),
            _tile(context, 'الرواتب', Icons.payments_outlined, AppColors.neonGreen, '/admin/payroll'),
            _tile(context, 'طلبات التسجيل', Icons.how_to_reg_outlined, AppColors.neonGold, '/admin/requests'),
            _tile(context, 'سجلات العمال', Icons.people_alt_outlined, AppColors.neonOrange, '/admin/workers'),
            _tile(context, 'الإعدادات', Icons.settings_outlined, AppColors.neonPurple, '/admin/settings'),
            _tile(context, 'سجلات التدقيق', Icons.history, AppColors.neonCyan, '/admin/audit'),
            _tile(context, 'التقارير', Icons.assessment_outlined, AppColors.neonPurple, '/admin/reports'),
            _tile(context, 'تسوية بنكية', Icons.account_balance_outlined, AppColors.neonCyan, '/admin/bank-reconciliation'),
            _tile(context, 'الإقرارات الضريبية', Icons.receipt_outlined, AppColors.neonGold, '/admin/tax-filings'),
            _tile(context, 'المشتريات', Icons.shopping_bag_outlined, AppColors.neonOrange, '/admin/purchases'),
            _tile(context, 'مردودات العملاء', Icons.assignment_return_outlined, AppColors.neonRed, '/admin/customer-returns'),
            _tile(context, 'تحليل التكاليف', Icons.pie_chart_outline, AppColors.neonPurple, '/admin/cost-analysis'),
            _tile(context, 'سير الموافقات', Icons.account_tree_outlined, AppColors.neonGreen, '/admin/approval-workflows'),
            _tile(context, 'الإعدادات المالية', Icons.tune_outlined, AppColors.neonCyan, '/admin/financial-settings'),
            _tile(context, 'الدردشة', Icons.chat_bubble_outline, AppColors.neonCyan, '/chat'),
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
