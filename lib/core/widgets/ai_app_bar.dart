import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Image.asset('assets/images/lamicoLogo.png', height: 32,
                  errorBuilder: (context, error, _) => const Icon(
                      Icons.show_chart, color: AppColors.neonPurple, size: 28)),
              const SizedBox(width: 8),
              Container(width: 1, height: 24,
                  color: AppColors.neonPurple.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: AppText.h3,
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
