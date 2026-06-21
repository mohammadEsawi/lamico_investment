import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  bool _saving = false;
  bool _savingProd = false;

  // System settings
  final _targetCtrl      = TextEditingController();
  final _electricCtrl    = TextEditingController();
  bool _notifProduction  = true;
  bool _notifMaintenance = true;
  bool _notifAttendance  = false;

  // Production settings
  final _capTargetCtrl      = TextEditingController();
  final _preformTargetCtrl  = TextEditingController();
  final _lowStockThCtrl     = TextEditingController();
  final _overtimeRateCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _targetCtrl.dispose(); _electricCtrl.dispose();
    _capTargetCtrl.dispose(); _preformTargetCtrl.dispose();
    _lowStockThCtrl.dispose(); _overtimeRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/settings/system'),
        ApiService.get('/settings/production'),
      ]);
      final sys  = results[0].data as Map<String, dynamic>? ?? {};
      final prod = results[1].data as Map<String, dynamic>? ?? {};
      setState(() {
        _targetCtrl.text   = '${sys['dailyProductionTarget'] ?? ''}';
        _electricCtrl.text = '${sys['electricityCostPerKwh'] ?? ''}';
        _notifProduction   = sys['notifProduction']  ?? true;
        _notifMaintenance  = sys['notifMaintenance'] ?? true;
        _notifAttendance   = sys['notifAttendance']  ?? false;
        _capTargetCtrl.text     = '${prod['capDailyTarget']      ?? prod['dailyCapTarget']     ?? ''}';
        _preformTargetCtrl.text = '${prod['preformDailyTarget']  ?? prod['dailyPreformTarget'] ?? ''}';
        _lowStockThCtrl.text    = '${prod['lowStockThreshold']   ?? ''}';
        _overtimeRateCtrl.text  = '${prod['overtimeRate']        ?? ''}';
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.put('/settings/system', data: {
        'dailyProductionTarget': int.tryParse(_targetCtrl.text) ?? 0,
        'electricityCostPerKwh': double.tryParse(_electricCtrl.text) ?? 0.0,
        'notifProduction':  _notifProduction,
        'notifMaintenance': _notifMaintenance,
        'notifAttendance':  _notifAttendance,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ إعدادات النظام',
              textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.neonGreen,
        ));
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProd() async {
    setState(() => _savingProd = true);
    try {
      await ApiService.put('/settings/production', data: {
        if (_capTargetCtrl.text.isNotEmpty)
          'capDailyTarget': int.tryParse(_capTargetCtrl.text) ?? 0,
        if (_preformTargetCtrl.text.isNotEmpty)
          'preformDailyTarget': int.tryParse(_preformTargetCtrl.text) ?? 0,
        if (_lowStockThCtrl.text.isNotEmpty)
          'lowStockThreshold': int.tryParse(_lowStockThCtrl.text) ?? 0,
        if (_overtimeRateCtrl.text.isNotEmpty)
          'overtimeRate': double.tryParse(_overtimeRateCtrl.text) ?? 0.0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حفظ إعدادات الإنتاج',
              textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.neonGreen,
        ));
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _savingProd = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الإعدادات'),
          Container(
            color: AppColors.bgCard,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppColors.neonPurple,
              labelColor: AppColors.neonPurple,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.settings_outlined),  text: 'النظام'),
                Tab(icon: Icon(Icons.factory_outlined),   text: 'الإنتاج'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : TabBarView(
                    controller: _tab,
                    children: [_buildSystem(), _buildProduction()],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSystem() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(textDirection: TextDirection.rtl, children: [
            const Icon(Icons.tune_outlined, color: AppColors.neonPurple),
            const SizedBox(width: 8),
            Text('الإعدادات العامة', style: AppText.h3),
          ]),
          const SizedBox(height: 16),
          Text('الهدف اليومي (كرتون)', style: AppText.caption, textDirection: TextDirection.rtl),
          const SizedBox(height: 6),
          _inputField(_targetCtrl, 'مثال: 500'),
          const SizedBox(height: 12),
          Text('تكلفة الكهرباء (ج.م/كيلوواط)', style: AppText.caption, textDirection: TextDirection.rtl),
          const SizedBox(height: 6),
          _inputField(_electricCtrl, 'مثال: 1.5'),
        ]),
      ),
      const SizedBox(height: 16),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(textDirection: TextDirection.rtl, children: [
            const Icon(Icons.notifications_outlined, color: AppColors.neonCyan),
            const SizedBox(width: 8),
            Text('الإشعارات', style: AppText.h3),
          ]),
          const SizedBox(height: 16),
          _switchTile('إشعارات الإنتاج', _notifProduction,
              (v) => setState(() => _notifProduction = v)),
          _switchTile('إشعارات الصيانة', _notifMaintenance,
              (v) => setState(() => _notifMaintenance = v)),
          _switchTile('إشعارات الحضور', _notifAttendance,
              (v) => setState(() => _notifAttendance = v)),
        ]),
      ),
      const SizedBox(height: 24),
      _saveButton(_saving, _save, 'حفظ إعدادات النظام'),
    ],
  );

  Widget _buildProduction() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(textDirection: TextDirection.rtl, children: [
            const Icon(Icons.factory_outlined, color: AppColors.neonOrange),
            const SizedBox(width: 8),
            Text('أهداف الإنتاج', style: AppText.h3),
          ]),
          const SizedBox(height: 16),
          Text('هدف الأغطية اليومي', style: AppText.caption, textDirection: TextDirection.rtl),
          const SizedBox(height: 6),
          _inputField(_capTargetCtrl, 'عدد الأغطية'),
          const SizedBox(height: 12),
          Text('هدف المخال اليومي', style: AppText.caption, textDirection: TextDirection.rtl),
          const SizedBox(height: 6),
          _inputField(_preformTargetCtrl, 'عدد المخال'),
        ]),
      ),
      const SizedBox(height: 16),
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(textDirection: TextDirection.rtl, children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.neonRed),
            const SizedBox(width: 8),
            Text('المخزون والرواتب', style: AppText.h3),
          ]),
          const SizedBox(height: 16),
          Text('حد المخزون المنخفض', style: AppText.caption, textDirection: TextDirection.rtl),
          const SizedBox(height: 6),
          _inputField(_lowStockThCtrl, 'مثال: 10'),
          const SizedBox(height: 12),
          Text('معدل الأوفرتايم (ج.م/ساعة)', style: AppText.caption, textDirection: TextDirection.rtl),
          const SizedBox(height: 6),
          _inputField(_overtimeRateCtrl, 'مثال: 25.0'),
        ]),
      ),
      const SizedBox(height: 24),
      _saveButton(_savingProd, _saveProd, 'حفظ إعدادات الإنتاج'),
    ],
  );

  Widget _saveButton(bool saving, VoidCallback onPressed, String label) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      onPressed: saving ? null : onPressed,
      child: saving
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );

  Widget _inputField(TextEditingController ctrl, String hint) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: TextField(
      controller: ctrl,
      textAlign: TextAlign.right,
      keyboardType: TextInputType.number,
      style: AppText.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint, hintStyle: AppText.body, border: InputBorder.none),
    ),
  );

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.body, textDirection: TextDirection.rtl),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.neonGreen,
        ),
      ],
    );
  }
}
