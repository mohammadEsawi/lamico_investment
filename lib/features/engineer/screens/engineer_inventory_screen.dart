import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerInventoryScreen extends StatefulWidget {
  const EngineerInventoryScreen({super.key});
  @override
  State<EngineerInventoryScreen> createState() => _EngineerInventoryScreenState();
}

class _EngineerInventoryScreenState extends State<EngineerInventoryScreen> {
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/engineer-inventory/mine');
      final data = res.data;
      setState(() {
        _sessions = data is List ? data : (data['inventory'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  void _showCreateSession() {
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('جرد جديد', style: AppText.h3),
            const SizedBox(height: 14),
            _field(notesCtrl, 'ملاحظات (اختياري)', AppColors.neonOrange, type: TextInputType.text, maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ApiService.post('/engineer-inventory', data: {
                      if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                    });
                    _load();
                  } catch (_) {}
                },
                child: const Text('إنشاء جرد',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showAddItem(Map<String, dynamic> session) {
    final nameCtrl  = TextEditingController();
    final qtyCtrl   = TextEditingController();
    final unitCtrl  = TextEditingController();
    final locCtrl   = TextEditingController();
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('إضافة مادة للجرد', style: AppText.h3),
              const SizedBox(height: 14),
              _field(nameCtrl, 'اسم المادة *', AppColors.neonOrange, type: TextInputType.text),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(qtyCtrl, 'الكمية *', AppColors.neonGreen)),
                const SizedBox(width: 10),
                Expanded(child: _field(unitCtrl, 'الوحدة', AppColors.neonCyan, type: TextInputType.text)),
              ]),
              const SizedBox(height: 10),
              _field(locCtrl, 'الموقع', AppColors.neonPurple, type: TextInputType.text),
              const SizedBox(height: 10),
              _field(notesCtrl, 'ملاحظات', AppColors.textSecondary, type: TextInputType.text),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final qty  = double.tryParse(qtyCtrl.text);
                    if (name.isEmpty || qty == null) return;
                    Navigator.pop(ctx);
                    try {
                      await ApiService.post('/engineer-inventory/${session['id']}/items', data: {
                        'name'    : name,
                        'quantity': qty,
                        if (unitCtrl.text.isNotEmpty)  'unit'    : unitCtrl.text.trim(),
                        if (locCtrl.text.isNotEmpty)   'location': locCtrl.text.trim(),
                        if (notesCtrl.text.isNotEmpty) 'notes'   : notesCtrl.text.trim(),
                      });
                      _load();
                    } catch (_) {}
                  },
                  child: const Text('إضافة',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> session, Map<String, dynamic> item) async {
    try {
      await ApiService.delete('/engineer-inventory/${session['id']}/items/${item['id']}');
      _load();
    } catch (_) {}
  }

  Future<void> _submit(Map<String, dynamic> session) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.patch('/engineer-inventory/${session['id']}/submit', data: {});
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('تم إرسال الجرد بنجاح',
            textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.neonGreen,
      ));
      _load();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('فشل إرسال الجرد', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'DRAFT':     return AppColors.neonGold;
      case 'SUBMITTED': return AppColors.neonCyan;
      case 'APPROVED':  return AppColors.neonGreen;
      case 'REJECTED':  return AppColors.neonRed;
      default:          return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'DRAFT':     return 'مسودة';
      case 'SUBMITTED': return 'مُرسَل';
      case 'APPROVED':  return 'موافق';
      case 'REJECTED':  return 'مرفوض';
      default:          return s ?? '--';
    }
  }

  Widget _field(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.number, int maxLines = 1}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: TextField(
        controller: ctrl, keyboardType: type,
        textAlign: TextAlign.right, maxLines: maxLines,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
            hintText: hint, hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonOrange,
        onPressed: _showCreateSession,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'جرد المهندس'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _sessions.isEmpty
                    ? const EmptyStateWidget(
                        message: 'لا توجد جرديات', icon: Icons.inventory_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _sessions.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 14),
                          itemBuilder: (_, i) {
                            final s = _sessions[i] as Map<String, dynamic>;
                            final status = s['status'] as String?;
                            final isDraft = status == 'DRAFT' || status == null;
                            final color = _statusColor(status);
                            final items = (s['items'] as List?) ?? [];
                            final date = (s['createdAt'] ?? '').toString();
                            return GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        date.length >= 10 ? date.substring(0, 10) : '--',
                                        style: AppText.h3,
                                        textDirection: TextDirection.rtl,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8)),
                                        child: Text(_statusLabel(status),
                                            style: AppText.label.copyWith(color: color)),
                                      ),
                                    ],
                                  ),
                                  if (s['notes'] != null && (s['notes'] as String).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(s['notes'],
                                          style: AppText.caption, textDirection: TextDirection.rtl),
                                    ),
                                  const SizedBox(height: 10),
                                  if (items.isNotEmpty) ...[
                                    ...items.map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          const Icon(Icons.circle, size: 6, color: AppColors.neonOrange),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${item['name'] ?? '--'}  —  ${item['quantity'] ?? '--'} ${item['unit'] ?? ''}',
                                              style: AppText.body, textDirection: TextDirection.rtl,
                                            ),
                                          ),
                                          if (isDraft)
                                            GestureDetector(
                                              onTap: () => _deleteItem(s, item as Map<String, dynamic>),
                                              child: const Icon(Icons.remove_circle_outline,
                                                  color: AppColors.neonRed, size: 18),
                                            ),
                                        ],
                                      ),
                                    )),
                                    const SizedBox(height: 8),
                                  ] else
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('لا توجد مواد مُضافة',
                                          style: AppText.caption.copyWith(color: AppColors.textSecondary),
                                          textDirection: TextDirection.rtl),
                                    ),
                                  if (isDraft)
                                    Row(textDirection: TextDirection.rtl, children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showAddItem(s),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('إضافة مادة',
                                              style: TextStyle(fontFamily: 'Cairo')),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.neonOrange),
                                        ),
                                      ),
                                      if (items.isNotEmpty) ...[
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _submit(s),
                                            icon: const Icon(Icons.send_outlined, size: 16),
                                            label: const Text('إرسال',
                                                style: TextStyle(fontFamily: 'Cairo')),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.neonGreen,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10))),
                                          ),
                                        ),
                                      ],
                                    ]),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}
