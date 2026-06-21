import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminMachinesScreen extends StatefulWidget {
  const AdminMachinesScreen({super.key});

  @override
  State<AdminMachinesScreen> createState() => _AdminMachinesScreenState();
}

class _AdminMachinesScreenState extends State<AdminMachinesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/machines/');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['machines'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'OPERATIONAL':
        return AppColors.neonGreen;
      case 'UNDER_MAINTENANCE':
        return AppColors.neonGold;
      case 'BROKEN':
        return AppColors.neonRed;
      case 'OFFLINE':
        return AppColors.textSecondary;
      case 'DECOMMISSIONED':
        return AppColors.textMuted;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'OPERATIONAL':
        return 'تشغيل';
      case 'UNDER_MAINTENANCE':
        return 'صيانة';
      case 'BROKEN':
        return 'معطّل';
      case 'OFFLINE':
        return 'مغلق';
      case 'DECOMMISSIONED':
        return 'مسحوب';
      default:
        return status ?? '--';
    }
  }

  Widget _inputField(TextEditingController ctrl, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body,
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _showMachineDialog({Map<String, dynamic>? machine}) {
    final nameCtrl = TextEditingController(text: machine?['name'] ?? '');
    final customTypeCtrl = TextEditingController();
    String? selectedType = machine?['type'];

    const builtInTypes = ['CAPS', 'PREFORM'];
    bool isCustomType = selectedType != null &&
        selectedType.isNotEmpty &&
        !builtInTypes.contains(selectedType);

    if (isCustomType) {
      customTypeCtrl.text = selectedType;
      selectedType = 'OTHER';
    }

    final isEdit = machine != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'تعديل الآلة' : 'إضافة آلة جديدة',
            style: AppText.h2,
            textDirection: TextDirection.rtl,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _inputField(nameCtrl, 'اسم الآلة'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedType,
                      hint: Text('نوع الآلة',
                          style: AppText.body,
                          textDirection: TextDirection.rtl),
                      dropdownColor: AppColors.bgCard,
                      style: AppText.body.copyWith(color: AppColors.textPrimary),
                      alignment: AlignmentDirectional.centerEnd,
                      items: const [
                        DropdownMenuItem(
                          value: 'CAPS',
                          child: Text('أغطية (CAPS)',
                              textDirection: TextDirection.rtl),
                        ),
                        DropdownMenuItem(
                          value: 'PREFORM',
                          child: Text('مخال (PREFORM)',
                              textDirection: TextDirection.rtl),
                        ),
                        DropdownMenuItem(
                          value: 'OTHER',
                          child: Text('نوع آخر', textDirection: TextDirection.rtl),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => selectedType = v),
                    ),
                  ),
                ),
                if (selectedType == 'OTHER') ...[
                  const SizedBox(height: 12),
                  _inputField(customTypeCtrl, 'أدخل نوع الآلة'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final type = selectedType == 'OTHER'
                    ? customTypeCtrl.text.trim()
                    : (selectedType ?? '');
                try {
                  if (isEdit) {
                    await ApiService.put('/machines/${machine['id']}',
                        data: {'name': name, 'type': type});
                  } else {
                    await ApiService.post('/machines/',
                        data: {'name': name, 'type': type});
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (_) {}
              },
              child: Text(isEdit ? 'حفظ' : 'إضافة',
                  style: const TextStyle(fontFamily: 'Cairo',
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSheet(Map<String, dynamic> machine) {
    const statuses = [
      ('OPERATIONAL', 'تشغيل', AppColors.neonGreen),
      ('UNDER_MAINTENANCE', 'صيانة', AppColors.neonGold),
      ('BROKEN', 'معطّل', AppColors.neonRed),
      ('OFFLINE', 'مغلق', AppColors.textSecondary),
      ('DECOMMISSIONED', 'مسحوب', AppColors.textMuted),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('تغيير حالة الآلة',
                style: AppText.h2, textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            ...statuses.map((s) {
              final (key, label, color) = s;
              final isCurrent = machine['status'] == key;
              return ListTile(
                textColor: AppColors.textPrimary,
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(label,
                    style: AppText.body.copyWith(color: color),
                    textDirection: TextDirection.rtl),
                trailing: isCurrent
                    ? const Icon(Icons.check, color: AppColors.neonGreen)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ApiService.put('/machines/${machine['id']}/status',
                        data: {'status': key});
                    _load();
                  } catch (_) {}
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> machine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف الآلة',
            style: AppText.h2, textDirection: TextDirection.rtl),
        content: Text(
          'هل تريد حذف الآلة "${machine['name']}"؟ لا يمكن التراجع عن هذا الإجراء.',
          style: AppText.body,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء',
                style: AppText.body.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.delete('/machines/${machine['id']}');
        _load();
      } catch (_) {}
    }
  }

  Widget _machineCard(Map<String, dynamic> m) {
    final status = m['status'] as String?;
    final color = _statusColor(status);
    final type = m['type'] as String? ?? '';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.precision_manufacturing, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(m['name'] ?? '--',
                        style: AppText.h3,
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (type.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.neonBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(type,
                                style: AppText.label
                                    .copyWith(color: AppColors.neonBlue)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(_statusLabel(status),
                                  style: AppText.label.copyWith(color: color)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _actionBtn(
                label: 'تعديل',
                icon: Icons.edit_outlined,
                color: AppColors.neonCyan,
                onTap: () => _showMachineDialog(machine: m),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                label: 'تغيير الحالة',
                icon: Icons.sync,
                color: AppColors.neonGold,
                onTap: () => _showStatusSheet(m),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                label: 'حذف',
                icon: Icons.delete_outline,
                color: AppColors.neonRed,
                onTap: () => _confirmDelete(m),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: AppText.label.copyWith(color: color),
                  textDirection: TextDirection.rtl),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 3),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonPurple,
        onPressed: () => _showMachineDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(
          children: [
            AiAppBar(
              title: 'إدارة الآلات',
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  onPressed: _load,
                ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const LoadingWidget()
                  : _items.isEmpty
                      ? const EmptyStateWidget(
                          message: 'لا توجد آلات مسجلة',
                          icon: Icons.precision_manufacturing_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _machineCard(Map<String, dynamic>.from(_items[i])),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
