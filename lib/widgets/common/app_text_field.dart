import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Polished text field with consistent styling
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: obscureText ? 1 : maxLines,
          enabled: enabled,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textHint,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppTheme.textSecondary)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : AppTheme.backgroundLight,
          ),
        ),
      ],
    );
  }
}
