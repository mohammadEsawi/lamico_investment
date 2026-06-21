import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminMaintenanceCostsScreen extends StatefulWidget {
  const AdminMaintenanceCostsScreen({super.key});
  @override
  State<AdminMaintenanceCostsScreen> createState() =>
      _AdminMaintenanceCostsScreenState();
}

class _AdminMaintenanceCostsScreenState
    extends State<AdminMaintenanceCostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _costs = [];
  List<dynamic> _machines = [];
  bool _loading = true;
  String? _filterMachineId;
  String _filterType = 'ALL';

  // form
  String? _fMachineId;
  String _fCostType = 'PARTS';
  final _fAmount = TextEditingController();
  final _fDesc = TextEditingController();
  final _fInvoice = TextEditingController();
  DateTime? _fPaidAt;
  bool _submitting = false;

  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _numFmt = NumberFormat('#,##0.00');

  static const _costTypes = {
    'PARTS': 'قطع غيار',
    'LABOR': 'عمالة',
    'EXTERNAL_SERVICE': 'خدمات خارجية',
    'OTHER': 'أخرى',
  };
  static const _costColors = {
    'PARTS': AppColors.neonCyan,
    'LABOR': AppColors.neonOrange,
    'EXTERNAL_SERVICE': AppColors.neonPurple,
    'OTHER': AppColors.neonGold,
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _fAmount.dispose();
    _fDesc.dispose();
    _fInvoice.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/maintenance-costs'),
        ApiService.get('/machines/'),
      ]);
      final d0 = results[0].data;
      final d1 = results[1].data;
      setState(() {
        _costs = d0 is List ? d0 : (d0['costs'] ?? d0['data'] ?? []);
        _machines = d1 is List ? d1 : (d1['machines'] ?? d1['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  List<dynamic> get _filtered {
    var list = _costs;
    if (_filterMachineId != null) {
      list = list.where((c) => c['machineId']?.toString() == _filterMachineId).toList();
    }
    if (_filterType != 'ALL') {
      list = list.where((c) => c['costType'] == _filterType).toList();
    }
    return list;
  }

  double get _total => _filtered.fold(0.0, (sum, c) {
        final a = c['amount'];
        return sum + (a is num ? a.toDouble() : 0.0);
      });

  Future<void> _edit(Map<String, dynamic> cost) async {
    String costType = cost['costType'] ?? 'PARTS';
    final amtCtrl = TextEditingController(text: '${cost['amount'] ?? ''}');
    final descCtrl = TextEditingController(text: cost['description'] ?? '');
    final invCtrl = TextEditingController(text: cost['invoiceNumber'] ?? '');
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('تعديل التكلفة', style: AppText.h3),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
                  child: DropdownButton<String>(
                    value: costType, isExpanded: true, underline: const SizedBox(),
                    items: _costTypes.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value, textDirection: TextDirection.rtl)))
                        .toList(),
                    onChanged: (v) => ss(() => costType = v!),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(controller: amtCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec('المبلغ (ر.س)'), textDirection: TextDirection.rtl),
                const SizedBox(height: 8),
                TextField(controller: descCtrl,
                    decoration: _dec('الوصف'), maxLines: 2, textDirection: TextDirection.rtl),
                const SizedBox(height: 8),
                TextField(controller: invCtrl,
                    decoration: _dec('رقم الفاتورة'), textDirection: TextDirection.rtl),
                const SizedBox(height: 12),
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonCyan,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            await ApiService.patch('/maintenance-costs/${cost['id']}',
                                data: {
                              'costType': costType,
                              'amount': double.tryParse(amtCtrl.text),
                              'description': descCtrl.text,
                              if (invCtrl.text.isNotEmpty)
                                'invoiceNumber': invCtrl.text,
                            });
                            _load();
                          } catch (_) {}
                        },
                        child: const Text('حفظ',
                            style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.bgCard,
                            title: const Text('تأكيد الحذف', style: AppText.h3,
                                textDirection: TextDirection.rtl),
                            content: const Text('هل تريد حذف هذه التكلفة؟',
                                style: AppText.body, textDirection: TextDirection.rtl),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('إلغاء')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('حذف',
                                      style: TextStyle(color: AppColors.neonRed))),
                            ],
                          ),
                        );
                        if (ok == true) {
                          try {
                            await ApiService.delete('/maintenance-costs/${cost['id']}');
                            _load();
                          } catch (_) {}
                        }
                      },
                      child: const Text('حذف', style: TextStyle(color: AppColors.neonRed)),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPaidAt() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fPaidAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _fPaidAt = d);
  }

  Future<void> _submit() async {
    if (_fMachineId == null || _fAmount.text.isEmpty || _fDesc.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة الحقول المطلوبة'),
            backgroundColor: AppColors.neonRed),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.post('/maintenance-costs', data: {
        'machineId': _fMachineId,
        'costType': _fCostType,
        'amount': double.tryParse(_fAmount.text) ?? 0,
        'description': _fDesc.text,
        if (_fInvoice.text.isNotEmpty) 'invoiceNumber': _fInvoice.text,
        if (_fPaidAt != null) 'paidAt': _fPaidAt!.toIso8601String(),
      });
      _fAmount.clear(); _fDesc.clear(); _fInvoice.clear();
      setState(() { _fMachineId = null; _fCostType = 'PARTS'; _fPaidAt = null; });
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ'), backgroundColor: AppColors.neonGreen),
      );
      _tabs.animateTo(0);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الحفظ'), backgroundColor: AppColors.neonRed),
      );
    } finally { setState(() => _submitting = false); }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label, filled: true, fillColor: AppColors.bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 4),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'تكاليف الصيانة'),
          TabBar(controller: _tabs,
              tabs: const [Tab(text: 'التكاليف'), Tab(text: 'إضافة تكلفة')]),
          Expanded(
            child: TabBarView(controller: _tabs,
                children: [_buildList(), _buildForm()]),
          ),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return Column(children: [
      if (!_loading && _costs.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي التكاليف', style: AppText.caption,
                    textDirection: TextDirection.rtl),
                Text('${_numFmt.format(_total)} ر.س',
                    style: AppText.h3.copyWith(color: AppColors.neonGold),
                    textDirection: TextDirection.rtl),
              ],
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String?>(
              value: _filterMachineId, isExpanded: true, underline: const SizedBox(),
              hint: const Text('كل الآلات', textDirection: TextDirection.rtl),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('كل الآلات', textDirection: TextDirection.rtl)),
                ..._machines.map((m) => DropdownMenuItem<String?>(
                    value: m['id'].toString(),
                    child: Text(m['name'] ?? '--', textDirection: TextDirection.rtl))),
              ],
              onChanged: (v) => setState(() => _filterMachineId = v),
            ),
          ),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: ['ALL', ..._costTypes.keys].map((t) {
            final selected = _filterType == t;
            final label = t == 'ALL' ? 'الكل' : (_costTypes[t] ?? t);
            final color = _costColors[t] ?? AppColors.neonCyan;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => setState(() => _filterType = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? color.withValues(alpha: 0.2) : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? color : AppColors.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Text(label,
                      style: AppText.label.copyWith(
                          color: selected ? color : AppColors.textSecondary)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _loading
            ? const LoadingWidget()
            : _filtered.isEmpty
                ? const Center(
                    child: Text('لا توجد تكاليف', textDirection: TextDirection.rtl))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final typeColor =
                            _costColors[c['costType']] ?? AppColors.neonGold;
                        final amount = c['amount'];
                        return GestureDetector(
                          onTap: () => _edit(c as Map<String, dynamic>),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(textDirection: TextDirection.rtl, children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: typeColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8)),
                                          child: Text(
                                              _costTypes[c['costType']] ??
                                                  c['costType'] ?? '--',
                                              style: AppText.label
                                                  .copyWith(color: typeColor)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(c['machine']?['name'] ?? '--',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                      ]),
                                      const SizedBox(height: 6),
                                      Text(c['description'] ?? '--',
                                          style: AppText.body,
                                          textDirection: TextDirection.rtl),
                                      if (c['createdBy'] != null)
                                        Text('بواسطة: ${c['createdBy']?['fullName'] ?? '--'}',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                      Text(
                                        c['createdAt'] != null
                                            ? _dateFmt.format(DateTime.parse(
                                                c['createdAt'].toString()))
                                            : '--',
                                        style: AppText.caption,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${amount is num ? _numFmt.format(amount) : '--'} ر.س',
                                  style: AppText.h3.copyWith(color: AppColors.neonGold),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(children: [
          _label('الآلة *'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String>(
              value: _fMachineId, isExpanded: true, underline: const SizedBox(),
              hint: const Text('اختر الآلة', textDirection: TextDirection.rtl),
              items: _machines
                  .map((m) => DropdownMenuItem<String>(
                      value: m['id'].toString(),
                      child: Text(m['name'] ?? '--', textDirection: TextDirection.rtl)))
                  .toList(),
              onChanged: (v) => setState(() => _fMachineId = v),
            ),
          ),
          const SizedBox(height: 12),
          _label('نوع التكلفة'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String>(
              value: _fCostType, isExpanded: true, underline: const SizedBox(),
              items: _costTypes.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, textDirection: TextDirection.rtl)))
                  .toList(),
              onChanged: (v) => setState(() => _fCostType = v!),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'المبلغ (ر.س) *', filled: true, fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fDesc, maxLines: 2, textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'الوصف *', filled: true, fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fInvoice, textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'رقم الفاتورة (اختياري)', filled: true, fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickPaidAt,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                  color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
              child: Row(textDirection: TextDirection.rtl, children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.neonGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  _fPaidAt != null ? _dateFmt.format(_fPaidAt!) : 'تاريخ الدفع (اختياري)',
                  style: AppText.body.copyWith(
                      color: _fPaidAt != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary),
                  textDirection: TextDirection.rtl,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('حفظ التكلفة',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppText.caption, textDirection: TextDirection.rtl),
      );
}
