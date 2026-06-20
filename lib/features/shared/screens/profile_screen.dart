import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
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
  bool _saving = false;

  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _bioCtrl    = TextEditingController();
  final _jobCtrl    = TextEditingController();
  final _deptCtrl   = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _bioCtrl.dispose();  _jobCtrl.dispose(); _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/profile/me');
      final data = res.data as Map<String, dynamic>;
      setState(() { _profile = data; _loading = false; });
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
    _nameCtrl.text  = _profile?['name']       ?? _profile?['fullName'] ?? '';
    _phoneCtrl.text = _profile?['phone']       ?? '';
    _bioCtrl.text   = _profile?['bio']         ?? '';
    _jobCtrl.text   = _profile?['jobTitle']    ?? '';
    _deptCtrl.text  = _profile?['department']  ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.put('/profile/me', data: {
        'fullName':   _nameCtrl.text.trim(),
        'phone':      _phoneCtrl.text.trim(),
        'bio':        _bioCtrl.text.trim(),
        'jobTitle':   _jobCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
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
          const SnackBar(content: Text('فشل الحفظ، حاول مرة أخرى')),
        );
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    try {
      final form = FormData.fromMap({
        'photo': await MultipartFile.fromFile(img.path, filename: img.name),
      });
      final res = await ApiService.postForm('/profile/me/photo', data: form);
      setState(() { _profile = res.data as Map<String, dynamic>; });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الصورة')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;
    final user   = AuthService.currentUser;
    final name   = _profile?['name'] ?? _profile?['fullName'] ?? user?.name ?? '';
    final email  = _profile?['email'] ?? user?.email ?? '--';
    final role   = user?.roleArabic ?? _profile?['role'] ?? '--';
    final photo  = _profile?['profileImage'] as String?;

    return Scaffold(
      backgroundColor: c.bg,
      body: AiBackground(
        child: Column(children: [
          AiAppBar(
            title: 'الملف الشخصي',
            actions: [
              if (!_editing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.neonPurple),
                  onPressed: _startEdit,
                ),
              if (_editing)
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text('حفظ',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.neonPurple,
                          fontWeight: FontWeight.w700)),
                ),
              if (_editing)
                IconButton(
                  icon: Icon(Icons.close, color: c.textSecondary),
                  onPressed: () => setState(() => _editing = false),
                ),
            ],
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Avatar ───────────────────────────────────────────
                      Center(
                        child: Column(children: [
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _editing ? _pickPhoto : null,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [
                                      AppColors.neonPurple.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ]),
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
                                    backgroundImage: (photo != null && photo.isNotEmpty)
                                        ? NetworkImage(photo) : null,
                                    child: (photo == null || photo.isEmpty)
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                            style: AppText.hero.copyWith(
                                                color: AppColors.neonPurple),
                                          )
                                        : null,
                                  ),
                                ),
                                if (_editing)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.neonPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 14),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!_editing) ...[
                            Text(name, style: AppText.h2.copyWith(color: c.textPrimary),
                                textDirection: TextDirection.rtl),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGrad,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(role,
                                  style: const TextStyle(
                                      fontFamily: 'Cairo', fontSize: 12,
                                      color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ]),
                      ),

                      // ── Edit Fields ───────────────────────────────────────
                      if (_editing) ...[
                        GlassCard(
                          child: Column(children: [
                            _field(_nameCtrl,  'الاسم الكامل',  Icons.person_outline),
                            const SizedBox(height: 12),
                            _field(_phoneCtrl, 'رقم الهاتف',    Icons.phone_outlined,
                                type: TextInputType.phone),
                            const SizedBox(height: 12),
                            _field(_jobCtrl,   'المسمى الوظيفي', Icons.work_outline),
                            const SizedBox(height: 12),
                            _field(_deptCtrl,  'القسم',          Icons.business_outlined),
                            const SizedBox(height: 12),
                            _field(_bioCtrl,   'نبذة شخصية',    Icons.notes_outlined,
                                maxLines: 3),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        if (_saving)
                          const Center(child: CircularProgressIndicator(
                              color: AppColors.neonPurple)),
                        const SizedBox(height: 12),
                      ],

                      // ── Info card ─────────────────────────────────────────
                      if (!_editing) GlassCard(
                        child: Column(children: [
                          _infoRow(Icons.email_outlined, 'البريد الإلكتروني', email),
                          _divider(c),
                          _infoRow(Icons.badge_outlined, 'الدور الوظيفي', role),
                          _divider(c),
                          _infoRow(Icons.toggle_on_outlined, 'الحالة',
                              (_profile?['isActive'] ?? user?.isActive ?? true)
                                  ? 'نشط' : 'غير نشط'),
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
                          if ((_profile?['bio'] as String?)?.isNotEmpty ?? false) ...[
                            _divider(c),
                            _infoRow(Icons.notes_outlined, 'نبذة شخصية',
                                _profile!['bio']),
                          ],
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // ── Theme Toggle ──────────────────────────────────────
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
                              activeColor: AppColors.neonPurple,
                              inactiveThumbColor: AppColors.neonGold,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Logout ────────────────────────────────────────────
                      GlassCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          textDirection: TextDirection.rtl,
                          leading: const Icon(Icons.logout,
                              color: AppColors.neonRed),
                          title: Text('تسجيل الخروج',
                              style: AppText.body.copyWith(
                                  color: AppColors.neonRed)),
                          onTap: _logout,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _divider(palette) => Divider(color: palette.border, height: 24);

  Widget _infoRow(IconData icon, String label, String value) {
    final c = context.colors;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, color: AppColors.neonPurple, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppText.label.copyWith(color: c.textMuted),
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 2),
              Text(value,
                  style: AppText.body.copyWith(color: c.textPrimary),
                  textDirection: TextDirection.rtl),
            ],
          ),
        ),
      ],
    );
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
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonPurple),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
