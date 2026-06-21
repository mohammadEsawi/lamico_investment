import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerSparePartRequestsScreen extends StatefulWidget {
  const EngineerSparePartRequestsScreen({super.key});
  @override
  State<EngineerSparePartRequestsScreen> createState() =>
      _EngineerSparePartRequestsScreenState();
}

class _EngineerSparePartRequestsScreenState
    extends State<EngineerSparePartRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _requests = [];
  List<dynamic> _machines = [];
  bool _loading = true;
  String _statusFilter = 'ALL';

  // form
  final _partNameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  String? _selectedMachineId;
  File? _photo;
  bool _submitting = false;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  static const _statuses = ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'ORDERED', 'RECEIVED'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _partNameCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.get('/spare-part-requests/mine'),
        ApiService.get('/machines/'),
      ]);
      final d0 = results[0].data;
      final d1 = results[1].data;
      setState(() {
        _requests = d0 is List ? d0 : (d0['requests'] ?? d0['data'] ?? []);
        _machines = d1 is List ? d1 : (d1['machines'] ?? d1['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  List<dynamic> get _filtered => _statusFilter == 'ALL'
      ? _requests
      : _requests.where((r) => r['status'] == _statusFilter).toList();

  Future<void> _markReceived(String id) async {
    try {
      await ApiService.patch('/spare-part-requests/$id/received', data: {});
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد الاستلام'), backgroundColor: AppColors.neonGreen),
      );
    } catch (_) {}
  }

  Future<void> _editRequest(Map<String, dynamic> r) async {
    final nameCtrl = TextEditingController(text: r['partName']);
    final qtyCtrl = TextEditingController(text: '${r['quantity'] ?? 1}');
    final notesCtrl = TextEditingController(text: r['notes'] ?? '');
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('تعديل الطلب', style: AppText.h3),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: _dec('اسم القطعة'), textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                decoration: _dec('الكمية'), textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: _dec('ملاحظات'),
                maxLines: 2, textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ApiService.patch('/spare-part-requests/${r['id']}', data: {
                      'partName': nameCtrl.text,
                      'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                      if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text,
                    });
                    _load();
                  } catch (_) {}
                },
                child: const Text('حفظ', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _photo = File(img.path));
  }

  Future<void> _submit() async {
    if (_partNameCtrl.text.isEmpty || _selectedMachineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة الحقول المطلوبة'), backgroundColor: AppColors.neonRed),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_photo != null) {
        final form = FormData.fromMap({
          'partName': _partNameCtrl.text,
          'machineId': _selectedMachineId,
          'quantity': int.tryParse(_qtyCtrl.text) ?? 1,
          if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
          'photo': await MultipartFile.fromFile(_photo!.path),
        });
        await ApiService.postMultipart('/spare-part-requests', form);
      } else {
        await ApiService.post('/spare-part-requests', data: {
          'partName': _partNameCtrl.text,
          'machineId': _selectedMachineId,
          'quantity': int.tryParse(_qtyCtrl.text) ?? 1,
          if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
        });
      }
      _partNameCtrl.clear();
      _qtyCtrl.text = '1';
      _notesCtrl.clear();
      setState(() { _selectedMachineId = null; _photo = null; });
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب'), backgroundColor: AppColors.neonGreen),
      );
      _tabs.animateTo(0);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الإرسال'), backgroundColor: AppColors.neonRed),
      );
    } finally { setState(() => _submitting = false); }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'PENDING':  return AppColors.neonGold;
      case 'APPROVED': return AppColors.neonGreen;
      case 'REJECTED': return AppColors.neonRed;
      case 'ORDERED':  return AppColors.neonCyan;
      case 'RECEIVED': return AppColors.neonPurple;
      default:         return AppColors.textSecondary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'PENDING':  return 'معلق';
      case 'APPROVED': return 'موافق';
      case 'REJECTED': return 'مرفوض';
      case 'ORDERED':  return 'تم الطلب';
      case 'RECEIVED': return 'تم الاستلام';
      default:         return s ?? '--';
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const EngineerNav(selectedIndex: 4),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'طلبات قطع الغيار'),
          TabBar(
            controller: _tabs,
            tabs: const [Tab(text: 'طلباتي'), Tab(text: 'طلب جديد')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_buildList(), _buildForm()],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: _statuses.map((s) {
            final selected = _statusFilter == s;
            final color = s == 'ALL' ? AppColors.neonCyan : _statusColor(s);
            final label = s == 'ALL' ? 'الكل' : _statusLabel(s);
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => setState(() => _statusFilter = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? color.withValues(alpha: 0.2) : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
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
      Expanded(
        child: _loading
            ? const LoadingWidget()
            : _filtered.isEmpty
                ? const Center(
                    child: Text('لا توجد طلبات', textDirection: TextDirection.rtl))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = _filtered[i];
                        final status = r['status'] as String?;
                        final color = _statusColor(status);
                        final unitPrice = r['unitPrice'];
                        final qty = r['quantity'] ?? 1;
                        return GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                textDirection: TextDirection.rtl,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(r['partName'] ?? '--',
                                        style: AppText.h3,
                                        textDirection: TextDirection.rtl),
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
                              const SizedBox(height: 6),
                              Text(
                                'الآلة: ${r['machine']?['name'] ?? '--'}  •  الكمية: $qty',
                                style: AppText.caption,
                                textDirection: TextDirection.rtl,
                              ),
                              Text(
                                unitPrice != null
                                    ? 'السعر: $unitPrice ر.س × $qty = ${(unitPrice * qty).toStringAsFixed(2)} ر.س'
                                    : 'لم يحدد السعر',
                                style: AppText.caption.copyWith(
                                    color: unitPrice != null
                                        ? AppColors.neonGold
                                        : AppColors.textSecondary),
                                textDirection: TextDirection.rtl,
                              ),
                              Text(
                                _dateFmt.format(DateTime.tryParse(
                                        r['createdAt']?.toString() ?? '') ??
                                    DateTime.now()),
                                style: AppText.caption,
                                textDirection: TextDirection.rtl,
                              ),
                              if (status == 'ORDERED' || status == 'APPROVED')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => _markReceived(r['id'].toString()),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.neonGreen),
                                      child: const Text('تأكيد الاستلام',
                                          style: TextStyle(fontFamily: 'Cairo')),
                                    ),
                                  ),
                                ),
                              if (status == 'PENDING')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AppColors.neonCyan, size: 20),
                                      onPressed: () =>
                                          _editRequest(r as Map<String, dynamic>),
                                    ),
                                  ),
                                ),
                            ],
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
          TextField(
            controller: _partNameCtrl,
            decoration: _dec('اسم القطعة *'),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedMachineId,
            decoration: _dec('الآلة *'),
            items: _machines
                .map((m) => DropdownMenuItem<String>(
                    value: m['id'].toString(),
                    child: Text(m['name'] ?? '--')))
                .toList(),
            onChanged: (v) => setState(() => _selectedMachineId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec('الكمية *'),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: _dec('ملاحظات'),
            maxLines: 3,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(children: [
              if (_photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_photo!, height: 120, fit: BoxFit.cover),
                ),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_photo == null ? 'إضافة صورة (اختياري)' : 'تغيير الصورة',
                    style: const TextStyle(fontFamily: 'Cairo')),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonCyan),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: _submitting
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('إرسال الطلب',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
