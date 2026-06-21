import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/app_text.dart';

class AiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const AiAppBar({
    required this.title,
    this.actions,
    this.leading,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final canGoBack = context.canPop();

    return Container(
      decoration: const BoxDecoration(
        color: Accent.blue,
        boxShadow: [BoxShadow(color: Color(0x262563EB), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // ── Back button (auto-shown when there's a page to pop) ──
              if (leading != null)
                ...[leading!, const SizedBox(width: 4)]
              else if (canGoBack)
                _BackButton(onPressed: () => context.pop()),

              // ── Logo ──
              Image.asset(
                'assets/images/lamicoLogo.png',
                height: 42,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.show_chart, color: Colors.white, size: 32),
              ),

              // ── Divider ──
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 10),

              // ── Title ──
              Expanded(
                child: Text(
                  title,
                  style: AppText.h3.copyWith(color: Colors.white),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── Actions ──
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }
}
