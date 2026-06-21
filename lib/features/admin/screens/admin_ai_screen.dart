import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminAiScreen extends StatefulWidget {
  const AdminAiScreen({super.key});

  @override
  State<AdminAiScreen> createState() => _AdminAiScreenState();
}

class _AdminAiScreenState extends State<AdminAiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Tab 1 — Invoice Extract
  XFile? _pickedFile;
  bool _extracting = false;
  dynamic _extractResult;
  String? _extractError;

  // Tab 2 — Anomaly Detection
  bool _detectingAnomalies = false;
  String? _anomalyResult;
  String? _anomalyError;

  // Tab 3 — Maintenance Report
  final _machineIdCtrl = TextEditingController();
  String _maintenancePeriod = 'last_30_days';
  bool _generatingMaintenance = false;
  String? _maintenanceResult;
  String? _maintenanceError;

  // Tab 4 — Shift Handover
  DateTime _handoverDate = DateTime.now();
  bool _generatingHandover = false;
  String? _handoverResult;
  String? _handoverError;

  // Tab 5 — Worker Coaching
  List<dynamic> _users = [];
  dynamic _coachingUserId;
  final _focusCtrl = TextEditingController();
  bool _generatingCoaching = false;
  String? _coachingResult;
  String? _coachingError;

  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _machineIdCtrl.dispose();
    _focusCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final res = await ApiService.get('/users/all');
      final data = res.data;
      setState(() {
        _users =
            data is List ? data : (data['users'] ?? data['data'] ?? []);
      });
    } catch (_) {}
  }

  // ── Tab 1: Invoice Extract ──────────────────────────────────────────────

  Future<void> _pickFile() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedFile = picked;
        _extractResult = null;
        _extractError = null;
      });
    }
  }

  Future<void> _extractInvoice() async {
    if (_pickedFile == null) return;
    setState(() {
      _extracting = true;
      _extractResult = null;
      _extractError = null;
    });
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _pickedFile!.path,
          filename: _pickedFile!.name,
        ),
      });
      final res = await ApiService.postMultipart('/ai/invoice-extract', formData);
      setState(() {
        _extractResult = res.data;
        _extracting = false;
      });
    } catch (e) {
      setState(() {
        _extractError = 'فشل استخراج الفاتورة. يرجى المحاولة مجدداً.';
        _extracting = false;
      });
    }
  }

  // ── Tab 2: Anomaly Detection ────────────────────────────────────────────

  Future<void> _detectAnomalies() async {
    setState(() {
      _detectingAnomalies = true;
      _anomalyResult = null;
      _anomalyError = null;
    });
    try {
      final res = await ApiService.post('/ai/detect-anomalies', data: {
        'data': {'timestamp': DateTime.now().toIso8601String()},
      });
      final d = res.data;
      setState(() {
        _anomalyResult = d is String
            ? d
            : (d['result'] ?? d['report'] ?? d['text'] ?? d.toString());
        _detectingAnomalies = false;
      });
    } catch (e) {
      setState(() {
        _anomalyError = 'فشل كشف الشذوذ. يرجى المحاولة مجدداً.';
        _detectingAnomalies = false;
      });
    }
  }

  // ── Tab 3: Maintenance Report ───────────────────────────────────────────

  Future<void> _generateMaintenanceReport() async {
    setState(() {
      _generatingMaintenance = true;
      _maintenanceResult = null;
      _maintenanceError = null;
    });
    try {
      final body = <String, dynamic>{'period': _maintenancePeriod};
      final machineId = _machineIdCtrl.text.trim();
      if (machineId.isNotEmpty) body['machineId'] = machineId;
      final res = await ApiService.post('/ai/maintenance-report', data: body);
      final d = res.data;
      setState(() {
        _maintenanceResult = d is String
            ? d
            : (d['result'] ?? d['report'] ?? d['text'] ?? d.toString());
        _generatingMaintenance = false;
      });
    } catch (e) {
      setState(() {
        _maintenanceError = 'فشل توليد التقرير. يرجى المحاولة مجدداً.';
        _generatingMaintenance = false;
      });
    }
  }

  // ── Tab 4: Shift Handover ───────────────────────────────────────────────

  Future<void> _pickHandoverDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _handoverDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _handoverDate = picked);
  }

  Future<void> _generateHandover() async {
    setState(() {
      _generatingHandover = true;
      _handoverResult = null;
      _handoverError = null;
    });
    try {
      final res = await ApiService.post('/ai/shift-handover', data: {
        'date': _handoverDate.toIso8601String(),
      });
      final d = res.data;
      setState(() {
        _handoverResult = d is String
            ? d
            : (d['result'] ?? d['report'] ?? d['text'] ?? d.toString());
        _generatingHandover = false;
      });
    } catch (e) {
      setState(() {
        _handoverError = 'فشل توليد ملخص التسليم. يرجى المحاولة مجدداً.';
        _generatingHandover = false;
      });
    }
  }

  // ── Tab 5: Worker Coaching ──────────────────────────────────────────────

  Future<void> _generateCoaching() async {
    setState(() {
      _generatingCoaching = true;
      _coachingResult = null;
      _coachingError = null;
    });
    try {
      final body = <String, dynamic>{};
      if (_coachingUserId != null) body['userId'] = _coachingUserId;
      final focus = _focusCtrl.text.trim();
      if (focus.isNotEmpty) body['focus'] = focus;
      final res = await ApiService.post('/ai/worker-coaching', data: body);
      final d = res.data;
      setState(() {
        _coachingResult = d is String
            ? d
            : (d['result'] ?? d['report'] ?? d['text'] ?? d.toString());
        _generatingCoaching = false;
      });
    } catch (e) {
      setState(() {
        _coachingError = 'فشل توليد التوصيات. يرجى المحاولة مجدداً.';
        _generatingCoaching = false;
      });
    }
  }

  // ── Shared Helpers ──────────────────────────────────────────────────────

  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) =>
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
          textDirection: TextDirection.rtl,
          keyboardType: keyboardType,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body,
            border: InputBorder.none,
          ),
        ),
      );

  Widget _dropdownField({
    required dynamic value,
    required List<dynamic> items,
    required String hint,
    required ValueChanged<dynamic> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<dynamic>(
            value: value,
            hint: Text(hint, style: AppText.body),
            isExpanded: true,
            dropdownColor: AppColors.bgCard,
            style: AppText.body.copyWith(color: AppColors.textPrimary),
            items: items.map((u) {
              return DropdownMenuItem<dynamic>(
                value: u['id'],
                child: Text(
                  u['fullName'] ?? u['name'] ?? '--',
                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                  textDirection: TextDirection.rtl,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _fieldLabel(String text) =>
      Text(text, style: AppText.label.copyWith(color: AppColors.textSecondary));

  Widget _aiButton({
    required String label,
    required VoidCallback? onPressed,
    required bool loading,
    Color color = AppColors.neonPurple,
    IconData icon = Icons.auto_awesome,
  }) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
              fontFamily: 'Cairo', color: Colors.white, fontSize: 14),
        ),
      );

  Widget _resultCard(String text) => GlassCard(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          textDirection: TextDirection.rtl,
          style: AppText.body.copyWith(
            color: AppColors.textPrimary,
            height: 1.7,
          ),
        ),
      );

  Widget _errorCard(String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.neonRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.error_outline, color: AppColors.neonRed, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: AppText.body.copyWith(color: AppColors.neonRed),
                  textDirection: TextDirection.rtl),
            ),
          ],
        ),
      );

  Widget _jsonResultCard(dynamic data) {
    String formatted;
    if (data is Map || data is List) {
      // Pretty-print JSON-like structure
      formatted = _prettyPrint(data, 0);
    } else {
      formatted = data.toString();
    }
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        formatted,
        textDirection: TextDirection.rtl,
        style: AppText.body.copyWith(
          color: AppColors.textPrimary,
          fontFamily: 'Roboto',
          height: 1.6,
        ),
      ),
    );
  }

  String _prettyPrint(dynamic val, int indent) {
    final pad = '  ' * indent;
    if (val is Map) {
      final entries = val.entries
          .map((e) => '$pad  ${e.key}: ${_prettyPrint(e.value, indent + 1)}')
          .join('\n');
      return '{\n$entries\n$pad}';
    } else if (val is List) {
      final items = val
          .map((e) => '$pad  ${_prettyPrint(e, indent + 1)}')
          .join('\n');
      return '[\n$items\n$pad]';
    } else {
      return val?.toString() ?? 'null';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 4),
      body: AiBackground(
        child: Column(
          children: [
            AiAppBar(title: 'مساعد الذكاء الاصطناعي'),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildInvoiceTab(),
                  _buildAnomalyTab(),
                  _buildMaintenanceTab(),
                  _buildHandoverTab(),
                  _buildCoachingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
              Tab(text: 'استخراج الفواتير'),
              Tab(text: 'كشف الشذوذ'),
              Tab(text: 'تقرير الصيانة'),
              Tab(text: 'تسليم الوردية'),
              Tab(text: 'تدريب العمال'),
            ],
          ),
        ),
      );

  // ── Tab 1 ───────────────────────────────────────────────────────────────

  Widget _buildInvoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('استخراج بيانات الفاتورة', style: AppText.h3),
                  const SizedBox(height: 6),
                  Text(
                    'اختر صورة أو ملف PDF لفاتورة لاستخراج بياناتها تلقائياً',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonPurple.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _pickedFile != null
                                ? Icons.check_circle_outline
                                : Icons.upload_file_outlined,
                            color: _pickedFile != null
                                ? AppColors.neonGreen
                                : AppColors.neonPurple,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pickedFile != null
                                ? _pickedFile!.name
                                : 'اضغط لاختيار صورة أو PDF',
                            style: AppText.body.copyWith(
                              color: _pickedFile != null
                                  ? AppColors.neonGreen
                                  : AppColors.neonPurple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _aiButton(
                    label: 'استخراج البيانات',
                    onPressed:
                        _pickedFile != null ? _extractInvoice : null,
                    loading: _extracting,
                    color: AppColors.neonPurple,
                    icon: Icons.document_scanner_outlined,
                  ),
                ],
              ),
            ),
            if (_extracting) ...[
              const SizedBox(height: 20),
              const LoadingWidget(),
              const SizedBox(height: 8),
              Center(
                child: Text('جارٍ استخراج البيانات...',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
            if (_extractError != null) ...[
              const SizedBox(height: 16),
              _errorCard(_extractError!),
            ],
            if (_extractResult != null) ...[
              const SizedBox(height: 16),
              Text('نتيجة الاستخراج', style: AppText.h3),
              const SizedBox(height: 8),
              _jsonResultCard(_extractResult),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tab 2 ───────────────────────────────────────────────────────────────

  Widget _buildAnomalyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('كشف الشذوذ', style: AppText.h3),
                  const SizedBox(height: 6),
                  Text(
                    'يقوم الذكاء الاصطناعي بتحليل بيانات الإنتاج والكهرباء للكشف عن أي قيم شاذة أو غير اعتيادية',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neonGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              AppColors.neonGold.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.neonGold, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتم تحليل أحدث بيانات النظام تلقائياً',
                            style: AppText.caption
                                .copyWith(color: AppColors.neonGold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _aiButton(
                    label: 'تشغيل الكشف',
                    onPressed: _detectAnomalies,
                    loading: _detectingAnomalies,
                    color: AppColors.neonOrange,
                    icon: Icons.search_outlined,
                  ),
                ],
              ),
            ),
            if (_detectingAnomalies) ...[
              const SizedBox(height: 20),
              const LoadingWidget(),
              const SizedBox(height: 8),
              Center(
                child: Text('جارٍ تحليل البيانات...',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
            if (_anomalyError != null) ...[
              const SizedBox(height: 16),
              _errorCard(_anomalyError!),
            ],
            if (_anomalyResult != null) ...[
              const SizedBox(height: 16),
              Text('نتائج الكشف', style: AppText.h3),
              const SizedBox(height: 8),
              _resultCard(_anomalyResult!),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tab 3 ───────────────────────────────────────────────────────────────

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('تقرير الصيانة', style: AppText.h3),
                  const SizedBox(height: 6),
                  Text(
                    'توليد تقرير صيانة ذكي بناءً على سجل الآلات والأعطال',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('رقم الآلة (اختياري)'),
                  const SizedBox(height: 6),
                  _inputField(_machineIdCtrl, 'اتركه فارغاً لجميع الآلات'),
                  const SizedBox(height: 14),
                  _fieldLabel('الفترة الزمنية'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _maintenancePeriod,
                        isExpanded: true,
                        dropdownColor: AppColors.bgCard,
                        style: AppText.body
                            .copyWith(color: AppColors.textPrimary),
                        items: const [
                          DropdownMenuItem(
                            value: 'last_7_days',
                            child: Text('آخر 7 أيام',
                                textDirection: TextDirection.rtl),
                          ),
                          DropdownMenuItem(
                            value: 'last_30_days',
                            child: Text('آخر 30 يوماً',
                                textDirection: TextDirection.rtl),
                          ),
                          DropdownMenuItem(
                            value: 'last_90_days',
                            child: Text('آخر 90 يوماً',
                                textDirection: TextDirection.rtl),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _maintenancePeriod = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _aiButton(
                    label: 'توليد التقرير',
                    onPressed: _generateMaintenanceReport,
                    loading: _generatingMaintenance,
                    color: AppColors.neonCyan,
                    icon: Icons.engineering_outlined,
                  ),
                ],
              ),
            ),
            if (_generatingMaintenance) ...[
              const SizedBox(height: 20),
              const LoadingWidget(),
              const SizedBox(height: 8),
              Center(
                child: Text('جارٍ توليد التقرير...',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
            if (_maintenanceError != null) ...[
              const SizedBox(height: 16),
              _errorCard(_maintenanceError!),
            ],
            if (_maintenanceResult != null) ...[
              const SizedBox(height: 16),
              Text('تقرير الصيانة', style: AppText.h3),
              const SizedBox(height: 8),
              _resultCard(_maintenanceResult!),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tab 4 ───────────────────────────────────────────────────────────────

  Widget _buildHandoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('تسليم الوردية', style: AppText.h3),
                  const SizedBox(height: 6),
                  Text(
                    'توليد ملخص تسليم وردية تلقائي يشمل الأحداث والمهام المهمة',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('تاريخ الوردية'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickHandoverDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: AppColors.neonCyan, size: 18),
                          Text(
                            _dateFmt.format(_handoverDate),
                            style: AppText.body.copyWith(
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _aiButton(
                    label: 'توليد التسليم',
                    onPressed: _generateHandover,
                    loading: _generatingHandover,
                    color: AppColors.neonGold,
                    icon: Icons.swap_horiz_outlined,
                  ),
                ],
              ),
            ),
            if (_generatingHandover) ...[
              const SizedBox(height: 20),
              const LoadingWidget(),
              const SizedBox(height: 8),
              Center(
                child: Text('جارٍ توليد ملخص التسليم...',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
            if (_handoverError != null) ...[
              const SizedBox(height: 16),
              _errorCard(_handoverError!),
            ],
            if (_handoverResult != null) ...[
              const SizedBox(height: 16),
              Text('ملخص تسليم الوردية', style: AppText.h3),
              const SizedBox(height: 8),
              _resultCard(_handoverResult!),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tab 5 ───────────────────────────────────────────────────────────────

  Widget _buildCoachingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('تدريب العمال', style: AppText.h3),
                  const SizedBox(height: 6),
                  Text(
                    'توليد توصيات تدريبية مخصصة بناءً على أداء العامل',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('الموظف (اختياري)'),
                  const SizedBox(height: 6),
                  _dropdownField(
                    value: _coachingUserId,
                    items: _users,
                    hint: 'اختر موظفاً أو اتركه عاماً',
                    onChanged: (v) =>
                        setState(() => _coachingUserId = v),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('موضوع التركيز (اختياري)'),
                  const SizedBox(height: 6),
                  _inputField(_focusCtrl,
                      'مثال: السلامة، الجودة، الإنتاجية...'),
                  const SizedBox(height: 16),
                  _aiButton(
                    label: 'توليد التوصيات',
                    onPressed: _generateCoaching,
                    loading: _generatingCoaching,
                    color: AppColors.neonGreen,
                    icon: Icons.school_outlined,
                  ),
                ],
              ),
            ),
            if (_generatingCoaching) ...[
              const SizedBox(height: 20),
              const LoadingWidget(),
              const SizedBox(height: 8),
              Center(
                child: Text('جارٍ توليد التوصيات...',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
            if (_coachingError != null) ...[
              const SizedBox(height: 16),
              _errorCard(_coachingError!),
            ],
            if (_coachingResult != null) ...[
              const SizedBox(height: 16),
              Text('التوصيات التدريبية', style: AppText.h3),
              const SizedBox(height: 8),
              _resultCard(_coachingResult!),
            ],
          ],
        ),
      ),
    );
  }
}
