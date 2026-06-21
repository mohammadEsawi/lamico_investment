import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';
import '../widgets/admin_nav.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/users/all');
      final data = res.data;
      setState(() {
        _users = data is List ? data : (data['users'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _toggleActive(String id, bool currentStatus) async {
    try {
      await ApiService.put('/users/$id', data: {'isActive': !currentStatus});
      _load();
    } catch (_) {}
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('تأكيد الحذف', style: AppText.h3,
            textDirection: TextDirection.rtl),
        content: const Text('هل أنت متأكد من حذف هذا المستخدم؟',
            style: AppText.body, textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('حذف',
                  style: TextStyle(color: AppColors.neonRed))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.delete('/users/$id');
        _load();
      } catch (_) {}
    }
  }

  Future<void> _changeRole(String id, String currentRole) async {
    String selectedRole = currentRole;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('تغيير دور المستخدم', style: AppText.h3),
              content: DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                dropdownColor: AppColors.bgCard,
                style: AppText.body.copyWith(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'ADMIN',      child: Text('مدير')),
                  DropdownMenuItem(value: 'ENGINEER',   child: Text('مهندس')),
                  DropdownMenuItem(value: 'ACCOUNTANT', child: Text('محاسب')),
                  DropdownMenuItem(value: 'WORKER',     child: Text('عامل')),
                  DropdownMenuItem(value: 'SALES_REP',  child: Text('مندوب مبيعات')),
                ],
                onChanged: (v) {
                  if (v != null) setStateDialog(() => selectedRole = v);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('إلغاء',
                      style: AppText.body.copyWith(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('تأكيد',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirm == true) {
      try {
        await ApiService.put('/users/$id/role', data: {'role': selectedRole});
        _load();
      } catch (_) {
        if (mounted) {
          messenger.showSnackBar(const SnackBar(
            content: Text('فشل تغيير الدور',
                textDirection: TextDirection.rtl),
            backgroundColor: AppColors.neonRed,
          ));
        }
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':      return AppColors.neonPurple;
      case 'ENGINEER':   return AppColors.neonCyan;
      case 'ACCOUNTANT': return AppColors.neonGreen;
      case 'WORKER':     return AppColors.neonOrange;
      case 'SALES_REP':  return AppColors.neonGold;
      default:           return AppColors.textSecondary;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMIN':      return 'مدير';
      case 'ENGINEER':   return 'مهندس';
      case 'ACCOUNTANT': return 'محاسب';
      case 'WORKER':     return 'عامل';
      case 'SALES_REP':  return 'مندوب مبيعات';
      default:           return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: const AdminNav(selectedIndex: 2),
      body: AiBackground(
        child: Column(children: [
          AiAppBar(title: 'المستخدمون'),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _users.isEmpty
                    ? const EmptyStateWidget(message: 'لا يوجد مستخدمون')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final u = _users[i];
                            final role = u['role'] ?? '';
                            final isActive = u['isActive'] ?? true;
                            final color = _roleColor(role);
                            return GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: color.withValues(alpha: 0.2),
                                    child: Text(
                                      (u['fullName'] ?? '?').toString().isNotEmpty
                                          ? (u['fullName'] as String)[0]
                                          : '?',
                                      style: AppText.h3.copyWith(color: color),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u['fullName'] ?? '--',
                                            style: AppText.h3,
                                            textDirection: TextDirection.rtl),
                                        Text(u['email'] ?? '--',
                                            style: AppText.caption,
                                            textDirection: TextDirection.rtl),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(_roleLabel(role),
                                              style: AppText.label.copyWith(color: color)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Switch(
                                        value: isActive,
                                        onChanged: (v) => _toggleActive(u['id'] ?? '', isActive),
                                        activeThumbColor: AppColors.neonGreen,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.manage_accounts_outlined,
                                                color: AppColors.neonPurple,
                                                size: 20),
                                            onPressed: () => _changeRole(
                                                u['id'] ?? '', role),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                color: AppColors.neonRed, size: 20),
                                            onPressed: () =>
                                                _deleteUser(u['id'] ?? ''),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
