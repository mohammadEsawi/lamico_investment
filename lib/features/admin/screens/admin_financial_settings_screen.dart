import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminFinancialSettingsScreen extends StatefulWidget {
  const AdminFinancialSettingsScreen({super.key});
  @override
  State<AdminFinancialSettingsScreen> createState() => _AdminFinancialSettingsScreenState();
}

class _AdminFinancialSettingsScreenState extends State<AdminFinancialSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  bool _loadingFin  = true;
  bool _loadingNotif = true;
  bool _savingFin   = false;
  bool _savingNotif = false;

  final Map<String, TextEditingController> _finCtrl = {};
  final Map<String, TextEditingController> _notifCtrl = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadFinancial();
    _loadNotifRules();
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in _finCtrl.values) { c.dispose(); }
    for (final c in _notifCtrl.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadFinancial() async {
    setState(() => _loadingFin = true);
    try {
      final res = await ApiService.get('/financial/settings');
      final data = res.data as Map<String, dynamic>? ?? {};
      _finCtrl.forEach((k, c) => c.dispose());
      _finCtrl.clear();
      data.forEach((k, v) {
        if (v is! Map && v is! List) _finCtrl[k] = TextEditingController(text: '$v');
      });
      setState(() => _loadingFin = false);
    } catch (_) { setState(() => _loadingFin = false); }
  }

  Future<void> _loadNotifRules() async {
    setState(() => _loadingNotif = true);
    try {
      final res = await ApiService.get('/settings/notification-rules');
      final data = res.data as Map<String, dynamic>? ?? {};
      _notifCtrl.forEach((k, c) => c.dispose());
      _notifCtrl.clear();
      data.forEach((k, v) {
        if (v is! Map && v is! List) _notifCtrl[k] = TextEditingController(text: '$v');
      });
      setState(() => _loadingNotif = false);
    } catch (_) { setState(() => _loadingNotif = false); }
  }

  Future<void> _saveFinancial() async {
    setState(() => _savingFin = true);
    try {
      final body = <String, dynamic>{};
      _finCtrl.forEach((k, c) {
        final v = c.text.trim();
        if (v.isEmpty) return;
        final num = double.tryParse(v);
        body[k] = num ?? v;
      });
      await ApiService.put('/financial/settings', data: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ الإعدادات المالية', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.neonGreen,
        ));
      }
    } catch (_) {} finally {
      if (mounted) { setState(() => _savingFin = false); }
    }
  }

  Future<void> _saveNotifRules() async {
    setState(() => _savingNotif = true);
    try {
      final body = <String, dynamic>{};
      _notifCtrl.forEach((k, c) {
        final v = c.text.trim();
        if (v.isEmpty) return;
        final num = double.tryParse(v);
        body[k] = num ?? v;
      });
      await ApiService.put('/settings/notification-rules', data: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ قواعد الإشعارات', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.neonGreen,
        ));
      }
    } catch (_) {} finally {
      if (mounted) { setState(() => _savingNotif = false); }
    }
  }

  Widget _settingsForm(Map<String, TextEditingController> ctrls, Color color,
      bool loading, bool saving, VoidCallback onSave) {
    if (loading) return const LoadingWidget();
    if (ctrls.isEmpty) {
      return const EmptyStateWidget(message: 'لا توجد إعدادات', icon: Icons.settings_outlined);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ...ctrls.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.key, style: AppText.caption, textDirection: TextDirection.rtl),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.3))),
                  child: TextField(
                    controller: e.value,
                    textAlign: TextAlign.right,
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                        border: InputBorder.none, isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ]),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الإعدادات المالية'),
          Container(
            color: AppColors.bgCard,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.neonGreen,
              labelColor: AppColors.neonGreen,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.attach_money_outlined), text: 'المالية'),
                Tab(icon: Icon(Icons.notifications_outlined), text: 'الإشعارات'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _settingsForm(_finCtrl, AppColors.neonGreen, _loadingFin, _savingFin, _saveFinancial),
                _settingsForm(_notifCtrl, AppColors.neonCyan, _loadingNotif, _savingNotif, _saveNotifRules),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
