import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/sales_nav.dart';

class SalesCustomersScreen extends StatefulWidget {
  const SalesCustomersScreen({super.key});
  @override
  State<SalesCustomersScreen> createState() => _SalesCustomersScreenState();
}

class _SalesCustomersScreenState extends State<SalesCustomersScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/sales-rep/customers');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['customers'] ?? data['data'] ?? []);
        AppDate.sortDesc(_items);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Widget _field(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.text}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: TextField(
        controller: ctrl, keyboardType: type, textAlign: TextAlign.right,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
            hintText: hint, hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );

  void _showForm([Map<String, dynamic>? customer]) {
    final isEdit    = customer != null;
    final nameCtrl  = TextEditingController(text: customer?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: customer?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: customer?['email'] ?? '');
    final cityCtrl  = TextEditingController(text: customer?['city'] ?? customer?['address'] ?? '');
    final notesCtrl = TextEditingController(text: customer?['notes'] ?? '');

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
              Text(isEdit ? 'تعديل العميل' : 'عميل جديد', style: AppText.h3),
              const SizedBox(height: 14),
              _field(nameCtrl,  'اسم العميل *',         AppColors.neonGold),
              const SizedBox(height: 10),
              _field(phoneCtrl, 'رقم الهاتف',           AppColors.neonGreen, type: TextInputType.phone),
              const SizedBox(height: 10),
              _field(emailCtrl, 'البريد الإلكتروني',   AppColors.neonCyan, type: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(cityCtrl,  'المدينة / العنوان',    AppColors.neonPurple),
              const SizedBox(height: 10),
              _field(notesCtrl, 'ملاحظات',              AppColors.textSecondary),
              const SizedBox(height: 16),
              if (isEdit) Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonRed),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            backgroundColor: AppColors.bgCard,
                            title: const Text('حذف العميل'),
                            content: const Text('هل تريد حذف هذا العميل؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                              TextButton(onPressed: () => Navigator.pop(c, true),
                                  child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
                            ],
                          ),
                        ),
                      );
                      if (ok == true) {
                        try { await ApiService.delete('/sales-rep/customers/${customer['id']}'); _load(); } catch (_) {}
                      }
                    },
                    child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _saveBtn(ctx, isEdit, customer, nameCtrl, phoneCtrl, emailCtrl, cityCtrl, notesCtrl)),
              ]) else SizedBox(
                width: double.infinity,
                child: _saveBtn(ctx, isEdit, customer, nameCtrl, phoneCtrl, emailCtrl, cityCtrl, notesCtrl),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _saveBtn(BuildContext ctx, bool isEdit, Map<String, dynamic>? customer,
      TextEditingController nameCtrl,  TextEditingController phoneCtrl,
      TextEditingController emailCtrl, TextEditingController cityCtrl,
      TextEditingController notesCtrl) =>
    ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () async {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;
        Navigator.pop(ctx);
        try {
          final body = {
            'name': name,
            if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text.trim(),
            if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text.trim(),
            if (cityCtrl.text.isNotEmpty)  'city':  cityCtrl.text.trim(),
            if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
          };
          if (isEdit) {
            await ApiService.patch('/sales-rep/customers/${customer!['id']}', data: body);
          } else {
            await ApiService.post('/sales-rep/customers', data: body);
          }
          _load();
        } catch (_) {}
      },
      child: Text(isEdit ? 'حفظ' : 'إضافة عميل',
          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const SalesNav(selectedIndex: 1),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGold,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'العملاء'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا يوجد عملاء', icon: Icons.people_outline)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final c = _items[i] as Map<String, dynamic>;
                            return GestureDetector(
                              onLongPress: () => _showForm(c),
                              child: GlassCard(
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.neonGold.withValues(alpha: 0.2),
                                      child: Text(
                                        (c['name'] ?? '?').toString().isNotEmpty
                                            ? (c['name'] as String)[0] : '?',
                                        style: AppText.h3.copyWith(color: AppColors.neonGold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c['name'] ?? '--', style: AppText.h3,
                                              textDirection: TextDirection.rtl),
                                          Text(c['phone'] ?? c['email'] ?? '--',
                                              style: AppText.caption, textDirection: TextDirection.rtl),
                                          Text(c['city'] ?? c['address'] ?? '--',
                                              style: AppText.label),
                                          if (c['createdAt'] != null)
                                            Text(AppDate.format(c['createdAt']),
                                                style: AppText.label.copyWith(color: AppColors.textSecondary),
                                                textDirection: TextDirection.rtl),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.more_vert, color: AppColors.textMuted, size: 18),
                                  ],
                                ),
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
