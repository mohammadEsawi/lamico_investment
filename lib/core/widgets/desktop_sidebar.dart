import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class DesktopSidebar extends StatelessWidget {
  final String role;
  const DesktopSidebar({required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final user = AuthService.currentUser;
    final sections = _sectionsFor(role);

    return SizedBox(
      width: 240,
      child: Material(
        color: AppColors.navBar,
        elevation: 8,
        child: Column(
          children: [
            // ── Logo ──
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/lamicoLogo.png',
                      height: 52,
                      errorBuilder: (_, error, stack) =>
                          const Icon(Icons.show_chart, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'لاميكو للاستثمار',
                      style: AppText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),

            // ── User info ──
            _UserInfoCard(name: user?.name, role: user?.roleArabic),

            const SizedBox(height: 4),
            Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
            const SizedBox(height: 4),

            // ── Nav items ──
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  children: [
                    for (final section in sections) ...[
                      if (section.label != null) _SectionLabel(section.label!),
                      for (final item in section.items)
                        _NavTile(item: item, currentPath: currentPath),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom: logout ──
            Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.logout, color: AppColors.neonRed, size: 20),
                title: Text('تسجيل الخروج',
                    style: AppText.body.copyWith(color: AppColors.neonRed, fontSize: 13)),
                onTap: () async {
                  await AuthService.logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<_Section> _sectionsFor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return [
          _Section(null, [
            _Item('الرئيسية',          Icons.home_outlined,                    '/admin'),
            _Item('التحليلات',          Icons.bar_chart_outlined,               '/admin/analytics'),
            _Item('المستخدمون',         Icons.people_outline,                   '/admin/users'),
            _Item('الآلات',             Icons.precision_manufacturing_outlined,  '/admin/machines'),
          ]),
          _Section('أدوات الإدارة', [
            _Item('الإنتاج',            Icons.factory_outlined,                 '/admin/production'),
            _Item('الصيانة',            Icons.build_outlined,                   '/admin/maintenance'),
            _Item('إدارة الكهرباء',    Icons.bolt_outlined,                    '/admin/electricity'),
            _Item('الرواتب',            Icons.payments_outlined,                '/admin/payroll'),
            _Item('الحضور',             Icons.fingerprint,                      '/admin/attendance'),
            _Item('الورديات',           Icons.schedule,                         '/admin/shifts'),
            _Item('الأداء',             Icons.trending_up_outlined,             '/admin/performance'),
            _Item('التقارير',           Icons.assessment_outlined,              '/admin/reports'),
            _Item('الذكاء الاصطناعي', Icons.auto_awesome_outlined,             '/admin/ai'),
          ]),
          _Section('عام', [
            _Item('المخزن',             Icons.inventory_2_outlined,             '/inventory'),
            _Item('الدردشة',            Icons.chat_bubble_outline,              '/chat'),
            _Item('الملف الشخصي',      Icons.person_outline,                   '/profile'),
          ]),
        ];

      case 'ENGINEER':
        return [
          _Section(null, [
            _Item('الرئيسية',          Icons.home_outlined,                    '/engineer'),
            _Item('الصيانة',           Icons.build_outlined,                   '/engineer/maintenance'),
            _Item('الجودة',            Icons.verified_outlined,                '/engineer/quality'),
          ]),
          _Section('الإنتاج والكهرباء', [
            _Item('تسجيل الإنتاج',    Icons.factory_outlined,                 '/engineer/production'),
            _Item('تسجيل الكهرباء',   Icons.bolt_outlined,                    '/engineer/electricity'),
            _Item('قطع الغيار',        Icons.settings_outlined,               '/engineer/spare-parts'),
            _Item('جدول الصيانة',     Icons.calendar_month_outlined,          '/engineer/maintenance-schedule'),
            _Item('صحة الآلات',       Icons.monitor_heart_outlined,           '/engineer/machine-health'),
          ]),
          _Section('عام', [
            _Item('المخزن',            Icons.inventory_2_outlined,             '/inventory'),
            _Item('الدردشة',           Icons.chat_bubble_outline,              '/chat'),
            _Item('الملف الشخصي',     Icons.person_outline,                   '/profile'),
          ]),
        ];

      case 'ACCOUNTANT':
        return [
          _Section(null, [
            _Item('الرئيسية',          Icons.home_outlined,                    '/accountant'),
            _Item('الفواتير',           Icons.receipt_long_outlined,            '/accountant/invoices'),
            _Item('التقارير المالية',  Icons.bar_chart_outlined,               '/accountant/reports'),
          ]),
          _Section('الإدارة المالية', [
            _Item('المصروفات',          Icons.money_off_outlined,               '/accountant/expenses'),
            _Item('الموردون',           Icons.store_outlined,                   '/accountant/suppliers'),
            _Item('مستحقات العملاء',   Icons.people_outline,                   '/accountant/receivables'),
            _Item('خطة الميزانية',     Icons.account_balance_outlined,         '/accountant/budget'),
            _Item('تحليل التكاليف',    Icons.pie_chart_outline,               '/admin/cost-analysis'),
            _Item('المشتريات',          Icons.shopping_bag_outlined,            '/admin/purchases'),
          ]),
          _Section('عام', [
            _Item('المخزن',            Icons.inventory_2_outlined,             '/inventory'),
            _Item('الدردشة',           Icons.chat_bubble_outline,              '/chat'),
            _Item('الملف الشخصي',     Icons.person_outline,                   '/profile'),
          ]),
        ];

      case 'WORKER':
        return [
          _Section(null, [
            _Item('الرئيسية',          Icons.home_outlined,                    '/worker'),
            _Item('الإنتاج',           Icons.inventory_2_outlined,             '/worker/production'),
            _Item('الحضور',            Icons.fingerprint,                      '/worker/attendance'),
            _Item('الأدوات',           Icons.handyman_outlined,                '/worker/tools'),
          ]),
          _Section('عام', [
            _Item('المخزن',            Icons.inventory_2_outlined,             '/inventory'),
            _Item('الدردشة',           Icons.chat_bubble_outline,              '/chat'),
            _Item('الملف الشخصي',     Icons.person_outline,                   '/profile'),
          ]),
        ];

      case 'SALES_REP':
        return [
          _Section(null, [
            _Item('الرئيسية',          Icons.home_outlined,                    '/sales'),
            _Item('العملاء',           Icons.people_outline,                   '/sales/customers'),
            _Item('عروض الأسعار',     Icons.request_quote_outlined,           '/sales/quotations'),
            _Item('الزيارات',          Icons.directions_car_outlined,          '/sales/visits'),
            _Item('الأهداف',           Icons.flag_outlined,                    '/sales/targets'),
          ]),
          _Section('عام', [
            _Item('المخزن',            Icons.inventory_2_outlined,             '/inventory'),
            _Item('الدردشة',           Icons.chat_bubble_outline,              '/chat'),
            _Item('الملف الشخصي',     Icons.person_outline,                   '/profile'),
          ]),
        ];

      default:
        return [];
    }
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _Item {
  final String label;
  final IconData icon;
  final String route;
  const _Item(this.label, this.icon, this.route);
}

class _Section {
  final String? label;
  final List<_Item> items;
  const _Section(this.label, this.items);
}

class _UserInfoCard extends StatelessWidget {
  final String? name;
  final String? role;
  const _UserInfoCard({this.name, this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? '',
                  style: AppText.body.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                if (role != null)
                  Text(role!,
                      style: AppText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
                      textDirection: TextDirection.rtl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Text(
        text,
        style: AppText.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w700),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _Item item;
  final String currentPath;
  const _NavTile({required this.item, required this.currentPath});

  bool get _active =>
      currentPath == item.route ||
      (item.route.length > 1 && currentPath.startsWith('${item.route}/'));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: _active
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(item.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(item.icon,
                    color: _active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.65),
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppText.body.copyWith(
                      color: _active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
                      fontWeight: _active ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                if (_active)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
