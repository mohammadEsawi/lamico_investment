import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/api_config.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving  = false;
  bool _uploading = false;

  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _jobCtrl      = TextEditingController();
  final _deptCtrl     = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _skillsCtrl   = TextEditingController();
  DateTime? _dateOfBirth;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _bioCtrl, _jobCtrl,
                     _deptCtrl, _addressCtrl, _linkedInCtrl, _skillsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res  = await ApiService.get('/profile/me');
      setState(() { _profile = res.data as Map<String, dynamic>; _loading = false; });
    } catch (_) {
      final user = AuthService.currentUser;
      if (user != null) {
        setState(() { _profile = user.toJson(); _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  void _startEdit() {
    _nameCtrl.text     = _profile?['fullName'] ?? _profile?['name'] ?? '';
    _phoneCtrl.text    = _profile?['phone']    ?? '';
    _bioCtrl.text      = _profile?['bio']      ?? '';
    _jobCtrl.text      = _profile?['jobTitle'] ?? '';
    _deptCtrl.text     = _profile?['department'] ?? '';
    _addressCtrl.text  = _profile?['address']  ?? '';
    _linkedInCtrl.text = _profile?['linkedIn'] ?? '';
    _skillsCtrl.text   = _profile?['skills']   ?? '';
    final dobStr = _profile?['dateOfBirth'] as String?;
    _dateOfBirth = dobStr != null ? DateTime.tryParse(dobStr) : null;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.put('/profile/me', data: {
        'fullName':    _nameCtrl.text.trim(),
        'phone':       _phoneCtrl.text.trim(),
        'bio':         _bioCtrl.text.trim(),
        'jobTitle':    _jobCtrl.text.trim(),
        'department':  _deptCtrl.text.trim(),
        'address':     _addressCtrl.text.trim(),
        'linkedIn':    _linkedInCtrl.text.trim(),
        'skills':      _skillsCtrl.text.trim(),
        if (_dateOfBirth != null)
          'dateOfBirth': _dateOfBirth!.toIso8601String(),
      });
      setState(() {
        _profile = res.data as Map<String, dynamic>;
        _editing = false;
        _saving  = false;
      });
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل الحفظ، حاول مرة أخرى')));
      }
    }
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (img == null || !mounted) return;
    try {
      final form = FormData.fromMap({
        'photo': await MultipartFile.fromFile(img.path, filename: img.name),
      });
      final res = await ApiService.postMultipart('/profile/me/photo', form);
      setState(() { _profile = res.data as Map<String, dynamic>; });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل رفع الصورة')));
      }
    }
  }

  Future<void> _uploadDocument() async {
    String selectedType = 'OTHER';
    final titleCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = context.colors;
        return StatefulBuilder(builder: (ctx, setS) => AlertDialog(
          backgroundColor: c.bgCard,
          title: Text('رفع مستند', style: AppText.h3.copyWith(color: c.textPrimary),
              textDirection: TextDirection.rtl),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: titleCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'عنوان المستند',
                labelStyle: AppText.body.copyWith(color: c.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'نوع المستند',
                labelStyle: AppText.body.copyWith(color: c.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButton<String>(
              value: selectedType,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: c.bgCard,
              items: const [
                DropdownMenuItem(value: 'CV',          child: Text('سيرة ذاتية')),
                DropdownMenuItem(value: 'CERTIFICATE', child: Text('شهادة')),
                DropdownMenuItem(value: 'OTHER',       child: Text('أخرى')),
              ],
              onChanged: (v) => setS(() => selectedType = v!),
            ),       // DropdownButton
          ),         // InputDecorator
        ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('اختر ملف')),
          ],
        ));
      },
    );

    if (confirm != true || !mounted) return;

    final file = await ImagePicker().pickMedia();
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final form = FormData.fromMap({
        'document': await MultipartFile.fromFile(file.path, filename: file.name),
        'title':    titleCtrl.text.trim().isEmpty ? file.name : titleCtrl.text.trim(),
        'documentType': selectedType,
      });
      await ApiService.postMultipart('/profile/me/documents', form);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل رفع المستند')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteDocument(int docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف', textDirection: TextDirection.rtl),
        content: const Text('هل تريد حذف هذا المستند؟', textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService.delete('/profile/me/documents/$docId');
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل الحذف')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  String _photoUrl(String? photo) {
    if (photo == null || photo.isEmpty) return '';
    if (photo.startsWith('http')) return photo;
    return '${ApiConfig.baseUrl}/pictures/$photo';
  }

  String _formatDate(String? iso) {
    if (iso == null) return '--';
    try {
      final d = DateTime.parse(iso);
      return '${d.year}/${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}';
    } catch (_) { return '--'; }
  }

  int get _completionPercent {
    final p = _profile;
    if (p == null) return 0;
    final fields = [
      p['fullName'], p['phone'], p['bio'], p['jobTitle'],
      p['department'], p['address'], p['skills'], p['profileImage'],
    ];
    final filled = fields.where((f) => f != null && f.toString().isNotEmpty).length;
    return ((filled / fields.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;
    final user   = AuthService.currentUser;
    final name   = _profile?['fullName'] ?? _profile?['name'] ?? user?.name ?? '';
    final email  = _profile?['email']    ?? user?.email ?? '--';
    final role   = user?.roleArabic      ?? '--';
    final photo  = _photoUrl(_profile?['profileImage'] as String?);
    final docs   = (_profile?['userDocuments'] as List?) ?? [];
    final pct    = _completionPercent;

    return Scaffold(
      backgroundColor: c.bg,
      body: AiBackground(
        child: Column(children: [
          AiAppBar(
            title: 'الملف الشخصي',
            actions: [
              if (!_editing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: _startEdit,
                  tooltip: 'تعديل',
                ),
              if (_editing) ...[
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text('حفظ',
                      style: AppText.body.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _editing = false),
                ),
              ],
            ],
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // ── Avatar + Name ──────────────────────────────────────
                      GlassCard(
                        child: Column(children: [
                          GestureDetector(
                            onTap: _editing ? _pickPhoto : null,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 52,
                                  backgroundColor: AppColors.neonPurple.withValues(alpha: 0.15),
                                  backgroundImage: photo.isNotEmpty
                                      ? NetworkImage(photo) : null,
                                  child: photo.isEmpty
                                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                          style: AppText.hero.copyWith(
                                              color: AppColors.neonPurple))
                                      : null,
                                ),
                                if (_editing)
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(
                                        color: AppColors.neonPurple, shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 14),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(name, style: AppText.h2.copyWith(color: c.textPrimary),
                              textDirection: TextDirection.rtl),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGrad,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(role, style: const TextStyle(
                                fontFamily: 'Cairo', fontSize: 12,
                                color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 16),
                          // ── Completion bar ──
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('اكتمال الملف الشخصي',
                                    style: AppText.caption.copyWith(color: c.textSecondary),
                                    textDirection: TextDirection.rtl),
                                Text('$pct%', style: AppText.label.copyWith(
                                    color: pct >= 80 ? AppColors.neonGreen : AppColors.neonOrange)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 6,
                                backgroundColor: c.bgSurface,
                                valueColor: AlwaysStoppedAnimation(
                                    pct >= 80 ? AppColors.neonGreen : AppColors.neonOrange),
                              ),
                            ),
                          ]),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── Edit Mode Fields ───────────────────────────────────
                      if (_editing) ...[
                        GlassCard(
                          child: Column(children: [
                            _sectionHeader('المعلومات الأساسية', Icons.person_outline,
                                AppColors.neonPurple),
                            const SizedBox(height: 12),
                            _field(_nameCtrl,    'الاسم الكامل',    Icons.person_outline),
                            _gap, _field(_phoneCtrl,  'رقم الهاتف',     Icons.phone_outlined,
                                type: TextInputType.phone),
                            _gap, _field(_jobCtrl,    'المسمى الوظيفي', Icons.work_outline),
                            _gap, _field(_deptCtrl,   'القسم',           Icons.business_outlined),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(children: [
                            _sectionHeader('معلومات إضافية', Icons.info_outline,
                                AppColors.neonCyan),
                            const SizedBox(height: 12),
                            _field(_addressCtrl, 'العنوان', Icons.location_on_outlined),
                            _gap, _field(_linkedInCtrl, 'رابط LinkedIn',
                                Icons.link, type: TextInputType.url),
                            _gap, _field(_skillsCtrl, 'المهارات (مفصولة بفاصلة)',
                                Icons.star_outline, maxLines: 2),
                            _gap,
                            // Date of birth picker
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: c.bgSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: c.border),
                                ),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    const Icon(Icons.cake_outlined,
                                        color: AppColors.neonPurple, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _dateOfBirth == null
                                          ? 'تاريخ الميلاد'
                                          : _formatDate(_dateOfBirth!.toIso8601String()),
                                      style: AppText.body.copyWith(
                                          color: _dateOfBirth == null
                                              ? c.textMuted : c.textPrimary),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(children: [
                            _sectionHeader('نبذة شخصية', Icons.notes_outlined,
                                AppColors.neonGreen),
                            const SizedBox(height: 12),
                            _field(_bioCtrl, 'نبذة شخصية', Icons.notes_outlined,
                                maxLines: 4),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        if (_saving)
                          const Center(child: CircularProgressIndicator(
                              color: AppColors.neonPurple)),
                        const SizedBox(height: 12),
                      ],

                      // ── View Mode: Info Card ───────────────────────────────
                      if (!_editing) ...[
                        GlassCard(
                          child: Column(children: [
                            _sectionHeader('المعلومات الشخصية', Icons.person_outline,
                                AppColors.neonPurple),
                            const SizedBox(height: 12),
                            _infoRow(Icons.email_outlined,  'البريد الإلكتروني', email),
                            _divider(c),
                            _infoRow(Icons.badge_outlined,  'الدور الوظيفي',     role),
                            _divider(c),
                            _infoRow(Icons.toggle_on_outlined, 'الحالة',
                                (_profile?['isActive'] ?? user?.isActive ?? true)
                                    ? 'نشط ✓' : 'غير نشط'),
                            if ((_profile?['username'] as String?)?.isNotEmpty ?? false) ...[
                              _divider(c),
                              _infoRow(Icons.alternate_email, 'اسم المستخدم',
                                  '@${_profile!['username']}'),
                            ],
                            if ((_profile?['phone'] as String?)?.isNotEmpty ?? false) ...[
                              _divider(c),
                              _infoRow(Icons.phone_outlined, 'الهاتف',
                                  _profile!['phone']),
                            ],
                            if ((_profile?['jobTitle'] as String?)?.isNotEmpty ?? false) ...[
                              _divider(c),
                              _infoRow(Icons.work_outline, 'المسمى الوظيفي',
                                  _profile!['jobTitle']),
                            ],
                            if ((_profile?['department'] as String?)?.isNotEmpty ?? false) ...[
                              _divider(c),
                              _infoRow(Icons.business_outlined, 'القسم',
                                  _profile!['department']),
                            ],
                            if (_profile?['dateOfBirth'] != null) ...[
                              _divider(c),
                              _infoRow(Icons.cake_outlined, 'تاريخ الميلاد',
                                  _formatDate(_profile!['dateOfBirth'] as String?)),
                            ],
                            if ((_profile?['address'] as String?)?.isNotEmpty ?? false) ...[
                              _divider(c),
                              _infoRow(Icons.location_on_outlined, 'العنوان',
                                  _profile!['address']),
                            ],
                            if (_profile?['createdAt'] != null) ...[
                              _divider(c),
                              _infoRow(Icons.calendar_today_outlined, 'عضو منذ',
                                  _formatDate(_profile!['createdAt'] as String?)),
                            ],
                          ]),
                        ),

                        const SizedBox(height: 16),

                        // ── Bio & Skills ───────────────────────────────────
                        if (((_profile?['bio'] as String?)?.isNotEmpty ?? false) ||
                            ((_profile?['skills'] as String?)?.isNotEmpty ?? false) ||
                            ((_profile?['linkedIn'] as String?)?.isNotEmpty ?? false)) ...[
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _sectionHeader('نبذة ومهارات', Icons.star_outline,
                                    AppColors.neonGold),
                                const SizedBox(height: 12),
                                if ((_profile?['bio'] as String?)?.isNotEmpty ?? false) ...[
                                  _infoRow(Icons.notes_outlined, 'نبذة شخصية',
                                      _profile!['bio']),
                                  _divider(c),
                                ],
                                if ((_profile?['skills'] as String?)?.isNotEmpty ?? false) ...[
                                  _infoRow(Icons.star_outline, 'المهارات',
                                      _profile!['skills']),
                                  _divider(c),
                                ],
                                if ((_profile?['linkedIn'] as String?)?.isNotEmpty ?? false)
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      const Icon(Icons.link, color: AppColors.neonBlue, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            final url = Uri.tryParse(_profile!['linkedIn']);
                                            if (url != null) await launchUrl(url);
                                          },
                                          child: Text(_profile!['linkedIn'],
                                              style: AppText.body.copyWith(
                                                  color: AppColors.neonBlue,
                                                  decoration: TextDecoration.underline),
                                              textDirection: TextDirection.rtl),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Documents ──────────────────────────────────────
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                textDirection: TextDirection.rtl,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(textDirection: TextDirection.rtl, children: [
                                    const Icon(Icons.folder_outlined,
                                        color: AppColors.neonOrange, size: 18),
                                    const SizedBox(width: 8),
                                    Text('المستندات',
                                        style: AppText.h3.copyWith(color: c.textPrimary),
                                        textDirection: TextDirection.rtl),
                                  ]),
                                  _uploading
                                      ? const SizedBox(width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: AppColors.neonOrange))
                                      : IconButton(
                                          icon: const Icon(Icons.add_circle_outline,
                                              color: AppColors.neonOrange, size: 22),
                                          onPressed: _uploadDocument,
                                          tooltip: 'إضافة مستند',
                                        ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (docs.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text('لا توجد مستندات مرفوعة',
                                        style: AppText.caption.copyWith(color: c.textMuted),
                                        textDirection: TextDirection.rtl),
                                  ),
                                )
                              else
                                ...docs.map((doc) {
                                  final d = doc as Map<String, dynamic>;
                                  final type = d['documentType'] as String? ?? 'OTHER';
                                  final typeColor = type == 'CV'
                                      ? AppColors.neonGreen
                                      : type == 'CERTIFICATE'
                                          ? AppColors.neonGold
                                          : AppColors.neonCyan;
                                  final typeAr = type == 'CV'
                                      ? 'سيرة ذاتية'
                                      : type == 'CERTIFICATE'
                                          ? 'شهادة'
                                          : 'مستند';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: typeColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(typeAr,
                                              style: AppText.label.copyWith(color: typeColor)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(d['title'] ?? d['fileName'] ?? '',
                                              style: AppText.body.copyWith(color: c.textPrimary),
                                              textDirection: TextDirection.rtl,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.neonRed, size: 18),
                                          onPressed: () => _deleteDocument(d['id'] as int),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],

                      // ── Theme Toggle ───────────────────────────────────────
                      GlassCard(
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                                color: AppColors.neonGold, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isDark ? 'الوضع الداكن' : 'الوضع الفاتح',
                                style: AppText.body.copyWith(color: c.textPrimary),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            Switch(
                              value: isDark,
                              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                              activeThumbColor: AppColors.neonPurple,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Logout ─────────────────────────────────────────────
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: AppColors.neonRed),
                          title: Text('تسجيل الخروج',
                              style: AppText.body.copyWith(color: AppColors.neonRed)),
                          onTap: () async {
                            final router = GoRouter.of(context);
                            await AuthService.logout();
                            router.go('/login');
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static const _gap = SizedBox(height: 12);

  Widget _sectionHeader(String title, IconData icon, Color color) {
    final c = context.colors;
    return Row(textDirection: TextDirection.rtl, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(title, style: AppText.h3.copyWith(color: c.textPrimary, fontSize: 14),
          textDirection: TextDirection.rtl),
    ]);
  }

  Widget _divider(Palette p) => Divider(color: p.border, height: 24);

  Widget _infoRow(IconData icon, String label, String value) {
    final c = context.colors;
    return Row(textDirection: TextDirection.rtl, children: [
      Icon(icon, color: AppColors.neonPurple, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.label.copyWith(color: c.textMuted),
              textDirection: TextDirection.rtl),
          const SizedBox(height: 2),
          Text(value, style: AppText.body.copyWith(color: c.textPrimary),
              textDirection: TextDirection.rtl),
        ]),
      ),
    ]);
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    final c = context.colors;
    return TextField(
      controller: ctrl,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      keyboardType: type,
      maxLines: maxLines,
      style: AppText.body.copyWith(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body.copyWith(color: c.textMuted),
        prefixIcon: Icon(icon, color: AppColors.neonPurple, size: 20),
        filled: true,
        fillColor: c.bgSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.neonPurple)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
