import 'package:flutter/material.dart';
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
    return Container(
      decoration: const BoxDecoration(
        color: Accent.blue,
        boxShadow: [BoxShadow(color: Color(0x262563EB), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Image.asset('assets/images/lamicoLogo.png', height: 32,
                  errorBuilder: (ctx, e, s) => const Icon(
                      Icons.show_chart, color: Colors.white, size: 28)),
              const SizedBox(width: 8),
              Container(width: 1, height: 24,
                  color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: AppText.h3.copyWith(color: Colors.white),
                    textDirection: TextDirection.rtl),
              ),
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}
