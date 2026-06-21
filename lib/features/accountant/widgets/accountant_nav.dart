import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
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
          case 3: _showAccountantHub(context); break;
          case 4: _showMore(context); break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: Colors.white),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: Colors.white),
          label: 'الفواتير',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: Colors.white),
          label: 'التقارير',
        ),
        NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps, color: Colors.white),
          label: 'أدواتي',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          selectedIcon: Icon(Icons.more_horiz, color: Colors.white),
          label: 'المزيد',
        ),
      ],
    );
  }

  void _showAccountantHub(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountantHubSheet(ctx: context),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            _tile(context, 'المخزن العام', Icons.inventory_2_outlined, AppColors.neonCyan, '/inventory'),
            _tile(context, 'الدردشة', Icons.chat_bubble_outline, AppColors.neonPurple, '/chat'),
            _tile(context, 'الملف الشخصي', Icons.person_outline, AppColors.textSecondary, '/profile'),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.neonRed),
              title: Text('تسجيل الخروج', style: AppText.body.copyWith(color: AppColors.neonRed)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService.logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
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

// ── Accountant Hub Sheet ──────────────────────────────────────────────────────

class _AccountantHubSheet extends StatelessWidget {
  final BuildContext ctx;
  const _AccountantHubSheet({required this.ctx});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20)],
        ),
        child: Column(children: [
          // ── Handle ──
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.successGrad,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أدوات المحاسب',
                        style: AppText.h2.copyWith(color: c.textPrimary),
                        textDirection: TextDirection.rtl),
                    Text('كل خدماتك المالية في مكان واحد',
                        style: AppText.caption, textDirection: TextDirection.rtl),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: c.border, height: 1),

          // ── Content ──
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                _section(context, 'الفواتير والمصروفات', AppColors.neonGreen, [
                  _HubItem('الفواتير',           Icons.receipt_long_outlined,          AppColors.neonGreen,  '/accountant/invoices'),
                  _HubItem('المصروفات',           Icons.money_off_outlined,             AppColors.neonRed,    '/accountant/expenses'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'الموردون والعملاء', AppColors.neonCyan, [
                  _HubItem('الموردون',            Icons.store_outlined,                 AppColors.neonGold,   '/accountant/suppliers'),
                  _HubItem('مستحقات العملاء',    Icons.people_outline,                 AppColors.neonCyan,   '/accountant/receivables'),
                  _HubItem('مستحقات الموردين',   Icons.business_outlined,              AppColors.neonOrange, '/accountant/payables'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'التخطيط المالي', AppColors.neonPurple, [
                  _HubItem('خطة الميزانية',      Icons.account_balance_outlined,       AppColors.neonPurple, '/accountant/budget'),
                  _HubItem('تحليل التكاليف',     Icons.pie_chart_outline,              AppColors.neonPurple, '/admin/cost-analysis'),
                  _HubItem('التقارير المالية',   Icons.bar_chart_outlined,             AppColors.neonBlue,   '/accountant/reports'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'الامتثال والضرائب', AppColors.neonGold, [
                  _HubItem('الإقرارات الضريبية', Icons.receipt_outlined,               AppColors.neonGold,   '/admin/tax-filings'),
                  _HubItem('التسوية البنكية',    Icons.account_balance_wallet_outlined, AppColors.neonCyan,   '/admin/bank-reconciliation'),
                  _HubItem('مردودات العملاء',    Icons.assignment_return_outlined,      AppColors.neonRed,    '/admin/customer-returns'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'المشتريات', AppColors.neonOrange, [
                  _HubItem('المشتريات',           Icons.shopping_bag_outlined,          AppColors.neonOrange, '/admin/purchases'),
                  _HubItem('سير الموافقات',      Icons.account_tree_outlined,          AppColors.neonGreen,  '/admin/approval-workflows'),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _section(BuildContext context, String title, Color accent, List<_HubItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(width: 3, height: 18,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: AppText.h3.copyWith(color: accent, fontSize: 13),
                textDirection: TextDirection.rtl),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: items.map((item) => _card(context, item)).toList(),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, _HubItem item) {
    final c = context.colors;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push(item.route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: item.color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(item.label,
                style: AppText.caption.copyWith(color: c.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _HubItem(this.label, this.icon, this.color, this.route);
}
