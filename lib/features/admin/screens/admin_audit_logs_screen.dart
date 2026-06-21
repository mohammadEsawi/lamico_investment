import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});
  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  final _userIdCtrl = TextEditingController();
  String? _entityType;
  DateTime? _startDate;
  DateTime? _endDate;

  static const _entityTypes = ['USER', 'PAYROLL', 'ATTENDANCE', 'MACHINE', 'PRODUCTION', 'INVENTORY'];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _userIdCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = <String, String>{};
      if (_userIdCtrl.text.isNotEmpty) params['userId'] = _userIdCtrl.text.trim();
      if (_entityType != null) params['entityType'] = _entityType!;
      if (_startDate != null) params['startDate'] = _startDate!.toIso8601String().substring(0, 10);
      if (_endDate != null)   params['endDate']   = _endDate!.toIso8601String().substring(0, 10);

      final query = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      final res = await ApiService.get('/audit/logs$query');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['logs'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) { _startDate = picked; } else { _endDate = picked; }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 0),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'سجلات التدقيق'),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(children: [
              Row(textDirection: TextDirection.rtl, children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12)),
                    child: TextField(
                      controller: _userIdCtrl,
                      textDirection: TextDirection.rtl,
                      style: AppText.body.copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          hintText: 'معرف المستخدم',
                          hintStyle: AppText.body,
                          border: InputBorder.none, isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12)),
                  child: DropdownButton<String>(
                    value: _entityType,
                    hint: Text('النوع', style: AppText.body),
                    dropdownColor: AppColors.bgCard,
                    underline: const SizedBox(),
                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('الكل')),
                      ..._entityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                    ],
                    onChanged: (v) => setState(() => _entityType = v),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Row(textDirection: TextDirection.rtl, children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_startDate == null ? 'من تاريخ'
                        : _startDate!.toIso8601String().substring(0, 10),
                        style: AppText.label),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonCyan,
                        side: const BorderSide(color: AppColors.neonCyan, width: 0.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_endDate == null ? 'إلى تاريخ'
                        : _endDate!.toIso8601String().substring(0, 10),
                        style: AppText.label),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonCyan,
                        side: const BorderSide(color: AppColors.neonCyan, width: 0.5)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                  onPressed: _load,
                  child: const Text('بحث', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ]),
            ]),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(message: 'لا توجد سجلات', icon: Icons.history)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final log = _items[i];
                            return GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.neonPurple.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.history,
                                            color: AppColors.neonPurple, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          log['action'] ?? log['event'] ?? '--',
                                          style: AppText.h3,
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                      Text(
                                        log['createdAt']?.toString().substring(0, 10) ?? '--',
                                        style: AppText.caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'المستخدم: ${log['user']?['name'] ?? log['userId'] ?? '--'}',
                                    style: AppText.caption,
                                    textDirection: TextDirection.rtl,
                                  ),
                                  if (log['details'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text('${log['details']}',
                                        style: AppText.caption,
                                        textDirection: TextDirection.rtl),
                                  ],
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
