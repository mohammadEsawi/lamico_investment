import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/engineer_nav.dart';

class EngineerDocumentsScreen extends StatefulWidget {
  const EngineerDocumentsScreen({super.key});
  @override
  State<EngineerDocumentsScreen> createState() => _EngineerDocumentsScreenState();
}

class _EngineerDocumentsScreenState extends State<EngineerDocumentsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/tech-documents');
      final data = res.data;
      setState(() {
        _items = data is List ? data : (data['documents'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _download(Map<String, dynamic> doc) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.patch('/tech-documents/${doc['id']}/download', data: {});
      final url = doc['fileUrl'] ?? doc['url'] ?? '';
      messenger.showSnackBar(SnackBar(
        content: Text(url.isNotEmpty ? 'رابط التنزيل: $url' : 'تم تسجيل التنزيل',
            textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: AppColors.neonCyan,
        duration: const Duration(seconds: 4),
      ));
      _load();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('فشل التنزيل', textDirection: TextDirection.rtl),
        backgroundColor: AppColors.neonRed,
      ));
    }
  }

  void _showUpload() {
    final titleCtrl    = TextEditingController();
    final categoryCtrl = TextEditingController();
    final descCtrl     = TextEditingController();
    XFile? file;

    showModalBottomSheet(
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
                Text('رفع وثيقة تقنية', style: AppText.h3),
                const SizedBox(height: 14),
                _inputField(titleCtrl,    'عنوان الوثيقة *', AppColors.neonCyan),
                const SizedBox(height: 10),
                _inputField(categoryCtrl, 'الفئة',           AppColors.neonPurple),
                const SizedBox(height: 10),
                _inputField(descCtrl,     'الوصف',           AppColors.textSecondary,
                    maxLines: 2, type: TextInputType.text),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) ss(() => file = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: file != null
                                ? AppColors.neonCyan
                                : AppColors.neonCyan.withValues(alpha: 0.3))),
                    child: Row(textDirection: TextDirection.rtl, children: [
                      const Icon(Icons.attach_file, color: AppColors.neonCyan),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          file != null ? file!.name : 'اختر ملف',
                          style: AppText.body.copyWith(
                              color: file != null ? AppColors.textPrimary : AppColors.textSecondary),
                          textDirection: TextDirection.rtl,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        if (file != null) {
                          final form = FormData.fromMap({
                            'title'   : title,
                            if (categoryCtrl.text.isNotEmpty) 'category': categoryCtrl.text.trim(),
                            if (descCtrl.text.isNotEmpty)     'description': descCtrl.text.trim(),
                            'file': await MultipartFile.fromFile(
                                file!.path, filename: file!.name),
                          });
                          await ApiService.postMultipart('/tech-documents', form);
                        } else {
                          await ApiService.post('/tech-documents', data: {
                            'title': title,
                            if (categoryCtrl.text.isNotEmpty) 'category': categoryCtrl.text.trim(),
                            if (descCtrl.text.isNotEmpty)     'description': descCtrl.text.trim(),
                          });
                        }
                        _load();
                      } catch (_) {}
                    },
                    child: const Text('رفع الوثيقة',
                        style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showEdit(Map<String, dynamic> doc) {
    final titleCtrl    = TextEditingController(text: doc['title'] ?? doc['name'] ?? '');
    final categoryCtrl = TextEditingController(text: doc['category'] ?? doc['type'] ?? '');
    final descCtrl     = TextEditingController(text: doc['description'] ?? '');

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
            Text('تعديل الوثيقة', style: AppText.h3),
            const SizedBox(height: 14),
            _inputField(titleCtrl,    'العنوان',  AppColors.neonCyan),
            const SizedBox(height: 10),
            _inputField(categoryCtrl, 'الفئة',    AppColors.neonPurple),
            const SizedBox(height: 10),
            _inputField(descCtrl,     'الوصف',    AppColors.textSecondary,
                maxLines: 2, type: TextInputType.text),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: AlertDialog(
                          backgroundColor: AppColors.bgCard,
                          title: const Text('حذف الوثيقة'),
                          content: const Text('هل تريد حذف هذه الوثيقة؟'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                            TextButton(onPressed: () => Navigator.pop(c, true),
                                child: const Text('حذف', style: TextStyle(color: AppColors.neonRed))),
                          ],
                        ),
                      ),
                    );
                    if (confirmed == true) {
                      try { await ApiService.delete('/tech-documents/${doc['id']}'); _load(); } catch (_) {}
                    }
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.neonRed),
                  child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ApiService.patch('/tech-documents/${doc['id']}', data: {
                        'title'   : titleCtrl.text.trim(),
                        if (categoryCtrl.text.isNotEmpty) 'category': categoryCtrl.text.trim(),
                        if (descCtrl.text.isNotEmpty)     'description': descCtrl.text.trim(),
                      });
                      _load();
                    } catch (_) {}
                  },
                  child: const Text('حفظ',
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, Color color,
      {TextInputType type = TextInputType.text, int maxLines = 1}) =>
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
        backgroundColor: AppColors.neonCyan,
        onPressed: _showUpload,
        child: const Icon(Icons.upload_file_outlined, color: Colors.white),
      ),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'الوثائق التقنية'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _items.isEmpty
                    ? const EmptyStateWidget(
                        message: 'لا توجد وثائق تقنية', icon: Icons.description_outlined)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final doc = _items[i];
                            final downloads = doc['downloadCount'] ?? doc['downloads'] ?? 0;
                            return GestureDetector(
                              onLongPress: () => _showEdit(doc as Map<String, dynamic>),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonCyan.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.description_outlined,
                                          color: AppColors.neonCyan),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(doc['title'] ?? doc['name'] ?? '--',
                                              style: AppText.h3, textDirection: TextDirection.rtl),
                                          Text(doc['category'] ?? doc['type'] ?? '--',
                                              style: AppText.caption, textDirection: TextDirection.rtl),
                                          Row(textDirection: TextDirection.rtl, children: [
                                            Text(doc['createdAt']?.toString().substring(0, 10) ?? '--',
                                                style: AppText.label.copyWith(
                                                    color: AppColors.textSecondary)),
                                            const SizedBox(width: 8),
                                            if (downloads > 0) ...[
                                              const Icon(Icons.download_done_outlined,
                                                  color: AppColors.neonGreen, size: 12),
                                              const SizedBox(width: 2),
                                              Text('$downloads',
                                                  style: AppText.label.copyWith(
                                                      color: AppColors.neonGreen)),
                                            ],
                                          ]),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download_outlined,
                                          color: AppColors.neonCyan, size: 22),
                                      onPressed: () => _download(doc as Map<String, dynamic>),
                                    ),
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
