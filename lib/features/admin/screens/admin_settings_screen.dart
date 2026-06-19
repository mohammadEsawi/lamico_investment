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

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  Map<String, dynamic>? _settings;
  bool _loading = true;
  bool _saving = false;

  final _targetCtrl      = TextEditingController();
  final _electricCtrl    = TextEditingController();
  bool _notifProduction  = true;
  bool _notifMaintenance = true;
  bool _notifAttendance  = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _targetCtrl.dispose(); _electricCtrl.dispose(); super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/settings/');
      final data = res.data as Map<String, dynamic>? ?? {};
      setState(() {
        _settings = data;
        _targetCtrl.text   = '${data['dailyProductionTarget'] ?? ''}';
        _electricCtrl.text = '${data['electricityCostPerKwh'] ?? ''}';
        _notifProduction   = data['notifProduction']  ?? true;
        _notifMaintenance  = data['notifMaintenance'] ?? true;
        _notifAttendance   = data['notifAttendance']  ?? false;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.put('/settings/', data: {
        'dailyProductionTarget': int.tryParse(_targetCtrl.text) ?? 0,
        'electricityCostPerKwh': double.tryParse(_electricCtrl.text) ?? 0.0,
        'notifProduction':  _notifProduction,
        'notifMaintenance': _notifMaintenance,
        'notifAttendance':  _notifAttendance,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعدادات',
              textDirection: TextDirection.rtl)),
        );
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _saving = false);
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
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(textDirection: TextDirection.rtl, children: [
                              const Icon(Icons.factory_outlined, color: AppColors.neonPurple),
                              const SizedBox(width: 8),
                              Text('إعدادات الإنتاج', style: AppText.h3),
                            ]),
                            const SizedBox(height: 16),
                            Text('الهدف اليومي (كرتون)', style: AppText.caption,
                                textDirection: TextDirection.rtl),
                            const SizedBox(height: 6),
                            _inputField(_targetCtrl, 'مثال: 500'),
                            const SizedBox(height: 12),
                            Text('تكلفة الكهرباء (ج.م/كيلوواط)', style: AppText.caption,
                                textDirection: TextDirection.rtl),
                            const SizedBox(height: 6),
                            _inputField(_electricCtrl, 'مثال: 1.5'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(textDirection: TextDirection.rtl, children: [
                              const Icon(Icons.notifications_outlined, color: AppColors.neonCyan),
                              const SizedBox(width: 8),
                              Text('إعدادات الإشعارات', style: AppText.h3),
                            ]),
                            const SizedBox(height: 16),
                            _switchTile('إشعارات الإنتاج', _notifProduction,
                                (v) => setState(() => _notifProduction = v)),
                            _switchTile('إشعارات الصيانة', _notifMaintenance,
                                (v) => setState(() => _notifMaintenance = v)),
                            _switchTile('إشعارات الحضور', _notifAttendance,
                                (v) => setState(() => _notifAttendance = v)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonPurple,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('حفظ الإعدادات',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

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
