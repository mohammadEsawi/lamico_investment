import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/glass_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> _materials = [];
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = AuthService.currentUser?.role == 'ADMIN';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/inventory/materials');
      final data = res.data;
      setState(() {
        _materials = data is List ? data : [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  int get _lowStockCount =>
      _materials.where((m) {
        final qty = (m['currentQuantity'] as num?)?.toDouble() ?? 0;
        final min = (m['minQuantity'] as num?)?.toDouble() ?? 0;
        return qty <= min;
      }).length;

  Color _progressColor(double qty, double min) {
    if (qty <= min) return AppColors.neonRed;
    if (qty <= min * 2) return AppColors.neonOrange;
    return AppColors.neonGreen;
  }

  double _progressValue(double qty, double min) {
    if (min <= 0) return 1.0;
    final ratio = qty / (min * 3);
    return ratio.clamp(0.0, 1.0);
  }

  void _showTransactionSheet(dynamic material, String type) {
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final refType = type == 'IN' ? 'PURCHASE' : 'PRODUCTION';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (type == 'IN' ? AppColors.neonGreen : AppColors.neonOrange)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      type == 'IN' ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      color: type == 'IN' ? AppColors.neonGreen : AppColors.neonOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type == 'IN' ? 'إضافة كمية' : 'خصم كمية',
                          style: AppText.h3.copyWith(color: context.colors.textPrimary),
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          material['name'] ?? '',
                          style: AppText.caption.copyWith(color: context.colors.textSecondary),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.rtl,
                style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  labelText: 'الكمية (${material['unit'] ?? ''})',
                  labelStyle: TextStyle(color: context.colors.textSecondary, fontFamily: 'Cairo'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonCyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  labelStyle: TextStyle(color: context.colors.textSecondary, fontFamily: 'Cairo'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonCyan),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        type == 'IN' ? AppColors.neonGreen : AppColors.neonOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final qty = double.tryParse(qtyCtrl.text.trim());
                    if (qty == null || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('أدخل كمية صحيحة')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ApiService.post('/inventory/transactions', data: {
                        'materialId': material['id'],
                        'type': type,
                        'quantity': qty,
                        'referenceType': refType,
                        'notes': notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      });
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(type == 'IN'
                                ? 'تمت إضافة الكمية بنجاح'
                                : 'تم خصم الكمية بنجاح'),
                            backgroundColor: AppColors.neonGreen,
                          ),
                        );
                        _load();
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('خطأ: ${e.toString()}'),
                            backgroundColor: AppColors.neonRed,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    type == 'IN' ? 'إضافة' : 'خصم',
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistorySheet(dynamic material) async {
    List<dynamic> transactions = [];
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheet) {
          if (loading) {
            ApiService.get('/inventory/materials/${material['id']}/transactions').then((res) {
              final data = res.data;
              setSheet(() {
                transactions = data is List ? data.take(20).toList() : [];
                loading = false;
              });
            }).catchError((_) {
              setSheet(() => loading = false);
            });
          }
          return Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              height: MediaQuery.of(ctx2).size.height * 0.65,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.history, color: AppColors.neonCyan, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سجل حركات: ${material['name'] ?? ''}',
                            style: AppText.h3.copyWith(color: context.colors.textPrimary),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : transactions.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد حركات',
                                  style: AppText.body.copyWith(
                                      color: context.colors.textSecondary),
                                  textDirection: TextDirection.rtl,
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: transactions.length,
                                separatorBuilder: (_, i) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final t = transactions[i];
                                  final isIn = t['type'] == 'IN';
                                  final createdBy = t['createdBy'];
                                  final createdAt = t['createdAt'] != null
                                      ? DateTime.tryParse(t['createdAt'])
                                      : null;
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.colors.bgSurface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: (isIn
                                                  ? AppColors.neonGreen
                                                  : AppColors.neonOrange)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Icon(
                                          isIn
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: isIn
                                              ? AppColors.neonGreen
                                              : AppColors.neonOrange,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${isIn ? '+' : '-'}${t['quantity']} ${material['unit'] ?? ''}',
                                                style: AppText.h3.copyWith(
                                                  color: isIn
                                                      ? AppColors.neonGreen
                                                      : AppColors.neonOrange,
                                                ),
                                                textDirection: TextDirection.rtl,
                                              ),
                                              if (createdBy != null)
                                                Text(
                                                  createdBy['fullName'] ?? '',
                                                  style: AppText.caption.copyWith(
                                                      color: context
                                                          .colors.textSecondary),
                                                  textDirection: TextDirection.rtl,
                                                ),
                                              if (createdAt != null)
                                                Text(
                                                  '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')}',
                                                  style: AppText.caption.copyWith(
                                                      color: context.colors.textMuted),
                                                  textDirection: TextDirection.rtl,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.neonCyan
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            t['referenceType'] == 'PURCHASE'
                                                ? 'شراء'
                                                : t['referenceType'] == 'PRODUCTION'
                                                    ? 'إنتاج'
                                                    : t['referenceType'] ?? '',
                                            style: AppText.caption.copyWith(
                                                color: AppColors.neonCyan),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateMaterialDialog() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final minCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: context.colors.bgCard,
          title: Text(
            'إضافة مادة خام جديدة',
            style: AppText.h3.copyWith(color: context.colors.textPrimary),
            textDirection: TextDirection.rtl,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(ctx, nameCtrl, 'اسم المادة'),
                const SizedBox(height: 12),
                _dialogField(ctx, unitCtrl, 'الوحدة (كيلوغرام / كرتونة ...)'),
                const SizedBox(height: 12),
                _dialogField(ctx, qtyCtrl, 'الكمية الحالية',
                    inputType: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField(ctx, minCtrl, 'الحد الأدنى للتنبيه',
                    inputType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: TextStyle(
                      color: context.colors.textSecondary, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final unit = unitCtrl.text.trim();
                if (name.isEmpty || unit.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الاسم والوحدة مطلوبان')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ApiService.post('/inventory/materials', data: {
                    'name': name,
                    'unit': unit,
                    'currentQuantity': double.tryParse(qtyCtrl.text) ?? 0,
                    'minQuantity': double.tryParse(minCtrl.text) ?? 0,
                  });
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('تمت إضافة المادة بنجاح'),
                        backgroundColor: AppColors.neonGreen,
                      ),
                    );
                    _load();
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('خطأ: ${e.toString()}'),
                        backgroundColor: AppColors.neonRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('إضافة',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMaterialDialog(dynamic material) {
    final nameCtrl = TextEditingController(text: material['name'] ?? '');
    final unitCtrl = TextEditingController(text: material['unit'] ?? '');
    final minCtrl = TextEditingController(
        text: (material['minQuantity'] ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: context.colors.bgCard,
          title: Text(
            'تعديل مادة خام',
            style: AppText.h3.copyWith(color: context.colors.textPrimary),
            textDirection: TextDirection.rtl,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(ctx, nameCtrl, 'اسم المادة'),
              const SizedBox(height: 12),
              _dialogField(ctx, unitCtrl, 'الوحدة'),
              const SizedBox(height: 12),
              _dialogField(ctx, minCtrl, 'الحد الأدنى للتنبيه',
                  inputType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: TextStyle(
                      color: context.colors.textSecondary, fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ApiService.delete(
                      '/inventory/materials/${material['id']}');
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف المادة'),
                        backgroundColor: AppColors.neonRed,
                      ),
                    );
                    _load();
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('خطأ في الحذف: ${e.toString()}'),
                        backgroundColor: AppColors.neonRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('حذف',
                  style: TextStyle(
                      color: AppColors.neonRed,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ApiService.put(
                      '/inventory/materials/${material['id']}',
                      data: {
                        'name': nameCtrl.text.trim(),
                        'unit': unitCtrl.text.trim(),
                        'minQuantity': double.tryParse(minCtrl.text) ?? 0,
                      });
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث المادة'),
                        backgroundColor: AppColors.neonGreen,
                      ),
                    );
                    _load();
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('خطأ: ${e.toString()}'),
                        backgroundColor: AppColors.neonRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    BuildContext ctx,
    TextEditingController ctrl,
    String label, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      textDirection: TextDirection.rtl,
      style: TextStyle(color: context.colors.textPrimary, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: context.colors.textSecondary, fontFamily: 'Cairo'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonCyan),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lowStock = _lowStockCount;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AiAppBar(
        title: 'المخزن - المواد الخام',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.neonGreen,
              onPressed: _showCreateMaterialDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          children: [
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        color: AppColors.neonCyan, size: 28),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_materials.length}',
                                      style: AppText.h1.copyWith(
                                          color: AppColors.neonCyan),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    Text(
                                      'إجمالي المواد',
                                      style: AppText.caption
                                          .copyWith(color: c.textSecondary),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: lowStock > 0
                                            ? AppColors.neonRed
                                            : AppColors.neonGreen,
                                        size: 28),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$lowStock',
                                      style: AppText.h1.copyWith(
                                          color: lowStock > 0
                                              ? AppColors.neonRed
                                              : AppColors.neonGreen),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    Text(
                                      'مخزون منخفض',
                                      style: AppText.caption
                                          .copyWith(color: c.textSecondary),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _materials.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'لا توجد مواد خام',
                              style: AppText.body.copyWith(color: c.textSecondary),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final m = _materials[i];
                                final qty =
                                    (m['currentQuantity'] as num?)?.toDouble() ??
                                        0;
                                final min =
                                    (m['minQuantity'] as num?)?.toDouble() ?? 0;
                                final color = _progressColor(qty, min);
                                final progress = _progressValue(qty, min);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onTap: () => _showHistorySheet(m),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              textDirection: TextDirection.rtl,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                        alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                      Icons.category_outlined,
                                                      color: color,
                                                      size: 20),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        m['name'] ?? '',
                                                        style: AppText.h3.copyWith(
                                                            color: c.textPrimary),
                                                        textDirection:
                                                            TextDirection.rtl,
                                                      ),
                                                      Text(
                                                        'الحد الأدنى: $min ${m['unit'] ?? ''}',
                                                        style:
                                                            AppText.caption.copyWith(
                                                                color:
                                                                    c.textSecondary),
                                                        textDirection:
                                                            TextDirection.rtl,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '$qty',
                                                  style: AppText.h2
                                                      .copyWith(color: color),
                                                  textDirection: TextDirection.rtl,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  m['unit'] ?? '',
                                                  style: AppText.caption.copyWith(
                                                      color: c.textSecondary),
                                                  textDirection: TextDirection.rtl,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor:
                                                    c.bgSurface,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        color),
                                                minHeight: 6,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              textDirection: TextDirection.rtl,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                if (_isAdmin)
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                    icon: const Icon(Icons.edit_outlined,
                                                        color: AppColors.neonCyan,
                                                        size: 20),
                                                    onPressed: () =>
                                                        _showEditMaterialDialog(m),
                                                  ),
                                                if (_isAdmin)
                                                  const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors
                                                        .neonGreen
                                                        .withValues(alpha: 0.15),
                                                    foregroundColor:
                                                        AppColors.neonGreen,
                                                    elevation: 0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8)),
                                                  ),
                                                  icon: const Icon(Icons.add,
                                                      size: 16),
                                                  label: const Text('إضافة',
                                                      style: TextStyle(
                                                          fontFamily: 'Cairo',
                                                          fontSize: 13)),
                                                  onPressed: () =>
                                                      _showTransactionSheet(m, 'IN'),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors
                                                        .neonOrange
                                                        .withValues(alpha: 0.15),
                                                    foregroundColor:
                                                        AppColors.neonOrange,
                                                    elevation: 0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8)),
                                                  ),
                                                  icon: const Icon(Icons.remove,
                                                      size: 16),
                                                  label: const Text('خصم',
                                                      style: TextStyle(
                                                          fontFamily: 'Cairo',
                                                          fontSize: 13)),
                                                  onPressed: () =>
                                                      _showTransactionSheet(
                                                          m, 'OUT'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _materials.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
