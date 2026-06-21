import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/accountant_nav.dart';

class AccountantSuppliersScreen extends StatefulWidget {
  const AccountantSuppliersScreen({super.key});
  @override
  State<AccountantSuppliersScreen> createState() => _AccountantSuppliersScreenState();
}

class _AccountantSuppliersScreenState extends State<AccountantSuppliersScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/suppliers');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['suppliers'] ?? data['data'] ?? []);
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

  void _showForm([Map<String, dynamic>? supplier]) {
    final isEdit     = supplier != null;
    final nameCtrl   = TextEditingController(text: supplier?['name'] ?? '');
    final phoneCtrl  = TextEditingController(text: supplier?['phone'] ?? '');
    final emailCtrl  = TextEditingController(text: supplier?['email'] ?? '');
    final addrCtrl   = TextEditingController(text: supplier?['address'] ?? '');
    final taxCtrl    = TextEditingController(text: supplier?['taxId'] ?? '');

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
              Text(isEdit ? 'تعديل المورد' : 'مورد جديد', style: AppText.h3),
              const SizedBox(height: 14),
              _field(nameCtrl,  'اسم المورد *',   AppColors.neonGold),
              const SizedBox(height: 10),
              _field(phoneCtrl, 'رقم الهاتف',     AppColors.neonCyan, type: TextInputType.phone),
              const SizedBox(height: 10),
              _field(emailCtrl, 'البريد الإلكتروني', AppColors.neonPurple, type: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(addrCtrl,  'العنوان',         AppColors.neonOrange),
              const SizedBox(height: 10),
              _field(taxCtrl,   'الرقم الضريبي',   AppColors.textSecondary),
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
                            title: const Text('حذف المورد'),
                            content: const Text('هل تريد حذف هذا المورد؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                              TextButton(onPressed: () => Navigator.pop(c, true),
                                  child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
                            ],
                          ),
                        ),
                      );
                      if (ok == true) {
                        try { await ApiService.delete('/suppliers/${supplier['id']}'); _load(); } catch (_) {}
                      }
                    },
                    child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _saveBtn(ctx, isEdit, supplier, nameCtrl, phoneCtrl, emailCtrl, addrCtrl, taxCtrl)),
              ])
              else SizedBox(
                width: double.infinity,
                child: _saveBtn(ctx, isEdit, supplier, nameCtrl, phoneCtrl, emailCtrl, addrCtrl, taxCtrl),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _saveBtn(BuildContext ctx, bool isEdit, Map<String, dynamic>? supplier,
      TextEditingController nameCtrl, TextEditingController phoneCtrl,
      TextEditingController emailCtrl, TextEditingController addrCtrl,
      TextEditingController taxCtrl) =>
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
            if (addrCtrl.text.isNotEmpty)  'address': addrCtrl.text.trim(),
            if (taxCtrl.text.isNotEmpty)   'taxId': taxCtrl.text.trim(),
          };
          if (isEdit) {
            await ApiService.patch('/suppliers/${supplier!['id']}', data: body);
          } else {
            await ApiService.post('/suppliers', data: body);
          }
          _load();
        } catch (_) {}
      },
      child: Text(isEdit ? 'حفظ' : 'إضافة مورد',
          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AccountantNav(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonGold,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الموردون'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا يوجد موردون', icon: Icons.store_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final s = _items[i] as Map<String, dynamic>;
                            return GestureDetector(
                              onLongPress: () => _showForm(s),
                              child: GlassCard(
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonGold.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.store, color: AppColors.neonGold),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s['name'] ?? '--', style: AppText.h3,
                                              textDirection: TextDirection.rtl),
                                          Text(s['phone'] ?? s['email'] ?? '--',
                                              style: AppText.caption, textDirection: TextDirection.rtl),
                                          Text(s['address'] ?? '--', style: AppText.label),
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
