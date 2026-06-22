import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/responsive.dart';

class EngineerNav extends StatelessWidget {
  final int selectedIndex;
  const EngineerNav({required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return const SizedBox.shrink();
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/engineer'); break;
          case 1: context.go('/engineer/maintenance'); break;
          case 2: context.go('/engineer/quality'); break;
          case 3: _showEngineerHub(context); break;
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
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build, color: Colors.white),
          label: 'الصيانة',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_outlined),
          selectedIcon: Icon(Icons.verified, color: Colors.white),
          label: 'الجودة',
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

  void _showEngineerHub(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EngineerHubSheet(ctx: context),
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

// ── Engineer Hub Sheet ────────────────────────────────────────────────────────

class _EngineerHubSheet extends StatelessWidget {
  final BuildContext ctx;
  const _EngineerHubSheet({required this.ctx});

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
                  child: const Icon(Icons.engineering, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أدوات المهندس',
                        style: AppText.h2.copyWith(color: c.textPrimary),
                        textDirection: TextDirection.rtl),
                    Text('كل خدماتك في مكان واحد',
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
                _section(context, 'الإنتاج والجودة', AppColors.neonGreen, [
                  _HubItem('تسجيل الإنتاج',    Icons.factory_outlined,        AppColors.neonOrange, '/engineer/production'),
                  _HubItem('فحوصات الجودة',    Icons.verified_outlined,       AppColors.neonGreen,  '/engineer/quality'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'الصيانة والمعدات', AppColors.neonOrange, [
                  _HubItem('الصيانة',           Icons.build_outlined,          AppColors.neonCyan,   '/engineer/maintenance'),
                  _HubItem('جدول الصيانة',     Icons.calendar_month_outlined,  AppColors.neonPurple, '/engineer/maintenance-schedule'),
                  _HubItem('تكاليف الصيانة',   Icons.receipt_long_outlined,    AppColors.neonOrange, '/engineer/maintenance-costs'),
                  _HubItem('صحة الآلات',       Icons.monitor_heart_outlined,   AppColors.neonGreen,  '/engineer/machine-health'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'الكهرباء والموارد', AppColors.neonGold, [
                  _HubItem('تسجيل الكهرباء',   Icons.bolt_outlined,           AppColors.neonGold,   '/engineer/electricity'),
                  _HubItem('قطع الغيار',        Icons.settings_outlined,       AppColors.neonGold,   '/engineer/spare-parts'),
                  _HubItem('طلبات قطع الغيار', Icons.shopping_cart_outlined,   AppColors.neonOrange, '/engineer/spare-part-requests'),
                  _HubItem('قراءات الآلات',    Icons.speed_outlined,           AppColors.neonCyan,   '/engineer/support-machine'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'الجرد والوثائق', AppColors.neonPurple, [
                  _HubItem('تنبيهات المواد',   Icons.warning_amber_outlined,   AppColors.neonRed,    '/engineer/raw-material-alerts'),
                  _HubItem('الجرد',            Icons.inventory_outlined,        AppColors.neonOrange, '/engineer/inventory'),
                  _HubItem('الوثائق التقنية',  Icons.description_outlined,     AppColors.neonCyan,   '/engineer/documents'),
                ]),
                const SizedBox(height: 16),
                _section(context, 'الحضور والمعدات', AppColors.neonCyan, [
                  _HubItem('الحضور',           Icons.fingerprint,              AppColors.neonGreen,  '/engineer/attendance'),
                  _HubItem('الآلات',           Icons.precision_manufacturing_outlined, AppColors.neonCyan, '/engineer/machines'),
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

// ── Engineer More Menu (app bar) ──────────────────────────────────────────────

class EngineerMoreMenu extends StatelessWidget {
  const EngineerMoreMenu({super.key});

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
        _item('/chat', 'الدردشة', Icons.chat_bubble_outline, AppColors.neonPurple),
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
            Text(label, style: AppText.body),
          ],
        ),
      );
}
