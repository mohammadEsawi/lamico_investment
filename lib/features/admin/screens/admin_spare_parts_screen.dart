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

class AdminSparePartsScreen extends StatefulWidget {
  const AdminSparePartsScreen({super.key});

  @override
  State<AdminSparePartsScreen> createState() => _AdminSparePartsScreenState();
}

class _AdminSparePartsScreenState extends State<AdminSparePartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Tab 1 – Spare Parts Stock
  List<dynamic> _parts = [];
  bool _loadingParts = true;

  // Tab 2 – Spare Part Requests
  List<dynamic> _requests = [];
  bool _loadingRequests = true;
  String _statusFilter = 'ALL';

  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadParts();
    _loadRequests();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ─── Data loaders ────────────────────────────────────────────────────────

  Future<void> _loadParts() async {
    setState(() => _loadingParts = true);
    try {
      final res = await ApiService.get('/spare-parts');
      final data = res.data;
      setState(() {
        _parts = data is List ? data : (data['data'] ?? data['spareParts'] ?? []);
        _loadingParts = false;
      });
    } catch (_) {
      setState(() => _loadingParts = false);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final res = await ApiService.get('/spare-part-requests');
      final data = res.data;
      setState(() {
        _requests = data is List ? data : (data['data'] ?? data['requests'] ?? []);
        _loadingRequests = false;
      });
    } catch (_) {
      setState(() => _loadingRequests = false);
    }
  }

  // ─── Filtered requests ───────────────────────────────────────────────────

  List<dynamic> get _filteredRequests {
    if (_statusFilter == 'ALL') return _requests;
    return _requests.where((r) => r['status'] == _statusFilter).toList();
  }

  // ─── Status helpers ──────────────────────────────────────────────────────

  String _statusLabel(String s) {
    switch (s) {
      case 'PENDING':
        return 'معلق';
      case 'APPROVED':
        return 'موافق عليه';
      case 'REJECTED':
        return 'مرفوض';
      case 'ORDERED':
        return 'تم الطلب';
      case 'RECEIVED':
        return 'تم الاستلام';
      default:
        return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING':
        return AppColors.neonGold;
      case 'APPROVED':
        return AppColors.neonGreen;
      case 'REJECTED':
        return AppColors.neonRed;
      case 'ORDERED':
        return AppColors.neonCyan;
      case 'RECEIVED':
        return const Color(0xFFA855F7); // purple
      default:
        return AppColors.textSecondary;
    }
  }

  // ─── Shared widgets ──────────────────────────────────────────────────────

  Widget _label(String text) =>
      Text(text, style: AppText.label.copyWith(color: AppColors.textSecondary));

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: TextField(
          controller: ctrl,
          textAlign: TextAlign.right,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body,
            border: InputBorder.none,
          ),
        ),
      );

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: AppText.caption.copyWith(color: color, fontSize: 11)),
      );

  void _confirmDelete({
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('تأكيد الحذف', style: AppText.h3),
          content: Text(message, style: AppText.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child:
                  Text('حذف', style: AppText.body.copyWith(color: AppColors.neonRed)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: Spare Parts Stock ────────────────────────────────────────────

  void _showPartForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final partNumCtrl = TextEditingController(text: existing?['partNumber'] ?? '');
    final categoryCtrl = TextEditingController(text: existing?['category'] ?? '');
    final qtyCtrl =
        TextEditingController(text: existing != null ? '${existing['quantity'] ?? ''}' : '');
    final unitCtrl =
        TextEditingController(text: existing?['unit'] ?? 'قطعة');
    final priceCtrl = TextEditingController(
        text: existing != null ? '${existing['unitPrice'] ?? ''}' : '');
    final locationCtrl = TextEditingController(text: existing?['location'] ?? '');
    final notesCtrl = TextEditingController(text: existing?['notes'] ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              right: 24,
              left: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'إضافة قطعة غيار' : 'تعديل قطعة الغيار',
                        style: AppText.h2,
                      ),
                      if (existing != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.neonRed),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDelete(
                              message:
                                  'هل أنت متأكد من حذف "${existing['name']}"؟',
                              onConfirm: () async {
                                try {
                                  await ApiService.delete(
                                      '/spare-parts/${existing['id']}');
                                  _loadParts();
                                } catch (_) {}
                              },
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label('اسم القطعة *'),
                  const SizedBox(height: 6),
                  _field(nameCtrl, 'اسم القطعة'),
                  const SizedBox(height: 12),

                  _label('رقم القطعة'),
                  const SizedBox(height: 6),
                  _field(partNumCtrl, 'رقم القطعة (اختياري)'),
                  const SizedBox(height: 12),

                  _label('الفئة'),
                  const SizedBox(height: 6),
                  _field(categoryCtrl, 'مثال: هيدروليك، كهرباء'),
                  const SizedBox(height: 12),

                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('الكمية'),
                            const SizedBox(height: 6),
                            _field(qtyCtrl, '0',
                                keyboard: const TextInputType.numberWithOptions(
                                    decimal: true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('الوحدة'),
                            const SizedBox(height: 6),
                            _field(unitCtrl, 'قطعة'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _label('سعر الوحدة'),
                  const SizedBox(height: 6),
                  _field(priceCtrl, 'السعر (اختياري)',
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),

                  _label('الموقع'),
                  const SizedBox(height: 6),
                  _field(locationCtrl, 'مثال: رف A-3 (اختياري)'),
                  const SizedBox(height: 12),

                  _label('ملاحظات'),
                  const SizedBox(height: 6),
                  _field(notesCtrl, 'ملاحظات اختيارية', maxLines: 3),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final payload = <String, dynamic>{
                        'name': name,
                      };
                      final partNum = partNumCtrl.text.trim();
                      if (partNum.isNotEmpty) payload['partNumber'] = partNum;
                      final cat = categoryCtrl.text.trim();
                      if (cat.isNotEmpty) payload['category'] = cat;
                      final qty = double.tryParse(qtyCtrl.text.trim());
                      if (qty != null) payload['quantity'] = qty;
                      final unit = unitCtrl.text.trim();
                      if (unit.isNotEmpty) payload['unit'] = unit;
                      final price = double.tryParse(priceCtrl.text.trim());
                      if (price != null) payload['unitPrice'] = price;
                      final loc = locationCtrl.text.trim();
                      if (loc.isNotEmpty) payload['location'] = loc;
                      final notes = notesCtrl.text.trim();
                      if (notes.isNotEmpty) payload['notes'] = notes;

                      try {
                        if (existing == null) {
                          await ApiService.post('/spare-parts', data: payload);
                        } else {
                          await ApiService.patch(
                              '/spare-parts/${existing['id']}',
                              data: payload);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadParts();
                      } catch (_) {}
                    },
                    child: Text(
                      existing == null ? 'إضافة' : 'حفظ التغييرات',
                      style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartsTab() {
    if (_loadingParts) return const LoadingWidget();
    if (_parts.isEmpty) {
      return const EmptyStateWidget(
        message: 'لا توجد قطع غيار مضافة',
        icon: Icons.build_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadParts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _parts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = _parts[i];
          final name = p['name'] ?? '--';
          final partNum = p['partNumber'] as String?;
          final category = p['category'] as String?;
          final qty = (p['quantity'] ?? 0);
          final minQty = (p['minQuantity'] ?? 0);
          final unit = p['unit'] ?? 'قطعة';
          final price = p['unitPrice'];
          final location = p['location'] as String?;
          final supplier = p['supplier'];
          final supplierName =
              supplier is Map ? supplier['name'] as String? : null;

          final qtyNum =
              qty is num ? qty.toDouble() : double.tryParse('$qty') ?? 0;
          final minNum =
              minQty is num ? minQty.toDouble() : double.tryParse('$minQty') ?? 0;
          final isLow = qtyNum < minNum;
          final qtyColor = isLow ? AppColors.neonRed : AppColors.neonGreen;

          return GestureDetector(
            onTap: () => _showPartForm(existing: Map<String, dynamic>.from(p)),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.build_outlined,
                            color: AppColors.neonPurple, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(name, style: AppText.h3, textDirection: TextDirection.rtl),
                            if (partNum != null && partNum.isNotEmpty)
                              Text(
                                partNum,
                                style: AppText.caption
                                    .copyWith(color: AppColors.textSecondary),
                                textDirection: TextDirection.rtl,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (category != null && category.isNotEmpty)
                        _badge(category, AppColors.neonBlue),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Wrap(
                    textDirection: TextDirection.rtl,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              color: qtyColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$qty $unit',
                            style: AppText.caption.copyWith(color: qtyColor),
                          ),
                          if (isLow) ...[
                            const SizedBox(width: 4),
                            _badge('منخفض', AppColors.neonRed),
                          ],
                        ],
                      ),
                      if (price != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(Icons.attach_money,
                                color: AppColors.neonGold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$price',
                              style: AppText.caption
                                  .copyWith(color: AppColors.neonGold),
                            ),
                          ],
                        ),
                      if (location != null && location.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.neonCyan, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: AppText.caption
                                  .copyWith(color: AppColors.neonCyan),
                            ),
                          ],
                        ),
                      if (supplierName != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.rtl,
                          children: [
                            const Icon(Icons.business_outlined,
                                color: AppColors.textSecondary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              supplierName,
                              style: AppText.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── TAB 2: Spare Part Requests ──────────────────────────────────────────

  void _showRequestDetails(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? 'PENDING';
    final priceCtrl = TextEditingController(
        text: req['unitPrice'] != null ? '${req['unitPrice']}' : '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              right: 24,
              left: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          req['partName'] ?? '--',
                          style: AppText.h2,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      _badge(_statusLabel(status), _statusColor(status)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Details grid
                  _detailRow(
                    'الماكينة',
                    () {
                      final m = req['machine'];
                      if (m is Map) return m['name'] as String? ?? '--';
                      return '--';
                    }(),
                    Icons.precision_manufacturing_outlined,
                    AppColors.neonCyan,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'الكمية',
                    '${req['quantity'] ?? '--'}',
                    Icons.inventory_2_outlined,
                    AppColors.neonPurple,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'مقدم الطلب',
                    () {
                      final rb = req['requestedBy'];
                      if (rb is Map) return rb['fullName'] as String? ?? '--';
                      return '--';
                    }(),
                    Icons.person_outline,
                    AppColors.neonBlue,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'تاريخ الطلب',
                    _formatDate(req['createdAt'] as String?),
                    Icons.calendar_today_outlined,
                    AppColors.textSecondary,
                  ),

                  if (req['notes'] != null &&
                      (req['notes'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _detailRow('ملاحظات', req['notes'] as String,
                        Icons.notes_outlined, AppColors.textSecondary),
                  ],

                  if (req['photoUrl'] != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        req['photoUrl'] as String,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 14),

                  // Price section
                  if (status == 'PENDING') ...[
                    _label('تحديد سعر الوحدة'),
                    const SizedBox(height: 6),
                    _field(
                      priceCtrl,
                      'أدخل السعر',
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final price =
                            double.tryParse(priceCtrl.text.trim());
                        if (price == null) return;
                        try {
                          await ApiService.patch(
                            '/spare-part-requests/${req['id']}/price',
                            data: {'unitPrice': price},
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadRequests();
                        } catch (_) {}
                      },
                      child: const Text(
                        'تحديد السعر',
                        style:
                            TextStyle(fontFamily: 'Cairo', color: Colors.white),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neonGold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.neonGold.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          const Icon(Icons.attach_money,
                              color: AppColors.neonGold, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            req['unitPrice'] != null
                                ? 'سعر الوحدة: ${req['unitPrice']}'
                                : 'لم يحدد السعر',
                            style: AppText.body
                                .copyWith(color: AppColors.neonGold),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Delete button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonRed,
                      side: const BorderSide(color: AppColors.neonRed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(
                      'حذف الطلب',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(
                        message: 'هل أنت متأكد من حذف طلب "${req['partName']}"؟',
                        onConfirm: () async {
                          try {
                            await ApiService.delete(
                                '/spare-part-requests/${req['id']}');
                            _loadRequests();
                          } catch (_) {}
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, Color color) =>
      Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: AppText.caption.copyWith(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: AppText.body.copyWith(color: AppColors.textPrimary),
              textDirection: TextDirection.rtl,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  String _formatDate(String? iso) {
    if (iso == null) return '--';
    try {
      return _dateFmt.format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  Widget _buildRequestsTab() {
    if (_loadingRequests) return const LoadingWidget();

    final statuses = ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'ORDERED', 'RECEIVED'];
    final statusLabels = {
      'ALL': 'الكل',
      'PENDING': 'معلق',
      'APPROVED': 'موافق',
      'REJECTED': 'مرفوض',
      'ORDERED': 'مطلوب',
      'RECEIVED': 'مستلم',
    };

    final visible = _filteredRequests;

    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: statuses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final s = statuses[i];
              final selected = _statusFilter == s;
              final chipColor = s == 'ALL' ? AppColors.neonPurple : _statusColor(s);
              return GestureDetector(
                onTap: () => setState(() => _statusFilter = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? chipColor.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? chipColor
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    statusLabels[s] ?? s,
                    style: AppText.caption.copyWith(
                      color: selected ? chipColor : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // List
        Expanded(
          child: visible.isEmpty
              ? const EmptyStateWidget(
                  message: 'لا توجد طلبات بهذا الفلتر',
                  icon: Icons.inbox_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final req = visible[i];
                      final partName = req['partName'] ?? '--';
                      final machine = req['machine'];
                      final machineName = machine is Map
                          ? machine['name'] as String? ?? '--'
                          : '--';
                      final qty = req['quantity'] ?? '--';
                      final status = req['status'] as String? ?? 'PENDING';
                      final rb = req['requestedBy'];
                      final requestedBy =
                          rb is Map ? rb['fullName'] as String? ?? '--' : '--';
                      final createdAt = req['createdAt'] as String?;
                      final unitPrice = req['unitPrice'];
                      final photoUrl = req['photoUrl'] as String?;

                      return GestureDetector(
                        onTap: () => _showRequestDetails(
                            Map<String, dynamic>.from(req)),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  // Photo thumbnail
                                  if (photoUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        photoUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Icons.broken_image_outlined,
                                              color: AppColors.textSecondary,
                                              size: 18),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                          Icons.build_circle_outlined,
                                          color: _statusColor(status),
                                          size: 20),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(partName,
                                            style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text(
                                          'ماكينة: $machineName  •  الكمية: $qty',
                                          style: AppText.caption.copyWith(
                                              color: AppColors.textSecondary),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _badge(
                                      _statusLabel(status), _statusColor(status)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(color: AppColors.border, height: 1),
                              const SizedBox(height: 10),
                              Row(
                                textDirection: TextDirection.rtl,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      const Icon(Icons.person_outline,
                                          color: AppColors.textSecondary,
                                          size: 14),
                                      const SizedBox(width: 4),
                                      Text(requestedBy,
                                          style: AppText.caption.copyWith(
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          color: AppColors.textSecondary,
                                          size: 14),
                                      const SizedBox(width: 4),
                                      Text(_formatDate(createdAt),
                                          style: AppText.caption.copyWith(
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  const Icon(Icons.attach_money,
                                      color: AppColors.neonGold, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    unitPrice != null
                                        ? '$unitPrice'
                                        : 'لم يحدد السعر',
                                    style: AppText.caption.copyWith(
                                      color: unitPrice != null
                                          ? AppColors.neonGold
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 4),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) {
          if (_tabs.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: AppColors.neonPurple,
            onPressed: () => _showPartForm(),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
      body: AiBackground(
        child: Column(
          children: [
            const AiAppBar(title: 'قطع الغيار'),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildPartsTab(),
                  _buildRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle:
                AppText.label.copyWith(color: AppColors.textPrimary),
            unselectedLabelStyle:
                AppText.label.copyWith(color: AppColors.textSecondary),
            tabs: const [
              Tab(text: 'قطع الغيار'),
              Tab(text: 'طلبات قطع الغيار'),
            ],
          ),
        ),
      );
}
