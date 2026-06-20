import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/ai_app_bar.dart';
import '../../../core/widgets/ai_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _groups = [];
  bool _loading = true;
  String? _selectedGroupId;
  String? _selectedGroupName;
  final List<Map<String, dynamic>> _messages = [];
  final _msgCtrl = TextEditingController();
  bool _inChat = false;

  @override
  void initState() { super.initState(); _loadGroups(); }

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/chat/groups');
      final data = res.data;
      setState(() {
        _groups = data is List ? data : (data['groups'] ?? data['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _openGroup(String groupId, String groupName) async {
    setState(() { _inChat = true; _selectedGroupId = groupId; _selectedGroupName = groupName; _messages.clear(); });
    SocketService.joinGroup(groupId);
    SocketService.onNewMessage((data) {
      if (mounted) setState(() => _messages.add(data as Map<String, dynamic>));
    });
    try {
      final res = await ApiService.get('/chat/groups/$groupId/messages');
      final data = res.data;
      final msgs = data is List ? data : (data['messages'] ?? data['data'] ?? []);
      setState(() => _messages.addAll(msgs.cast<Map<String, dynamic>>()));
    } catch (_) {}
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _selectedGroupId == null) return;
    SocketService.sendMessage({'groupId': _selectedGroupId, 'content': text});
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AiBackground(
        child: Column(children: [
          AiAppBar(
            title: _inChat ? (_selectedGroupName ?? 'الدردشة') : 'الدردشة',
            leading: _inChat
                ? IconButton(
                    icon: const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
                    onPressed: () => setState(() { _inChat = false; _selectedGroupId = null; }),
                  )
                : null,
          ),
          if (!_inChat)
            Expanded(
              child: _loading
                  ? const LoadingWidget()
                  : _groups.isEmpty
                      ? const EmptyStateWidget(message: 'لا توجد مجموعات دردشة', icon: Icons.chat_bubble_outline)
                      : RefreshIndicator(
                          onRefresh: _loadGroups,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _groups.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final g = _groups[i];
                              return GestureDetector(
                                onTap: () => _openGroup(
                                    g['id']?.toString() ?? '',
                                    g['name'] ?? 'مجموعة'),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppColors.neonCyan.withValues(alpha: 0.2),
                                        child: const Icon(Icons.group, color: AppColors.neonCyan, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(g['name'] ?? '--', style: AppText.h3,
                                                textDirection: TextDirection.rtl),
                                            Text(g['lastMessage'] ?? 'لا توجد رسائل',
                                                style: AppText.caption, textDirection: TextDirection.rtl,
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      Text(g['updatedAt']?.toString().substring(11, 16) ?? '',
                                          style: AppText.label),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            )
          else ...[
            Expanded(
              child: _messages.isEmpty
                  ? const EmptyStateWidget(message: 'لا توجد رسائل', icon: Icons.chat_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m = _messages[i];
                        final isMe = m['senderId'] == AuthService.currentUser?.id;
                        return Align(
                          alignment: isMe ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isMe ? AppColors.primaryGrad : null,
                              color: isMe ? null : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.72,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(m['sender']?['name'] ?? '--',
                                      style: AppText.label.copyWith(color: AppColors.neonCyan)),
                                Text(m['content'] ?? m['message'] ?? '',
                                    style: AppText.body.copyWith(color: AppColors.textPrimary),
                                    textDirection: TextDirection.rtl),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              color: AppColors.bgCard,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: AppText.body.copyWith(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                          hintStyle: AppText.body,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGrad,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
