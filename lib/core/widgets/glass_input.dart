import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class GlassInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const GlassInput({
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    super.key,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: AppText.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppText.body,
          prefixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textMuted, size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : Icon(widget.icon, color: AppColors.textMuted, size: 20),
          suffixIcon: !widget.isPassword
              ? null
              : Icon(widget.icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
