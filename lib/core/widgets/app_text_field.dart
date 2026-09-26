import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.autofocus = false,
    this.maxLength,
    required this.hint,
    this.inputFormatters = const [],
    this.icon,
    this.controller,
    this.textInputAction = TextInputAction.done,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  final bool autofocus;

  final int? maxLength;

  final String hint;

  final List<TextInputFormatter> inputFormatters;

  final IconData? icon;

  final TextEditingController? controller;

  final TextInputAction textInputAction;

  final TextInputType? keyboardType;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = this.icon;
    final maxLength = this.maxLength;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border, width: AppSpacing.hairline),
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: colors.surface,
      ),
      height: AppSpacing.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: colors.textSecondary, size: AppSpacing.iconSm), const SizedBox(width: AppSpacing.md)],
          Expanded(
            child: TextField(
              autofocus: autofocus,
              controller: controller,
              decoration: InputDecoration.collapsed(
                hintStyle: AppTextStyles.body.copyWith(color: colors.textSecondary),
                hintText: hint,
              ),
              inputFormatters: [...inputFormatters, if (maxLength != null) LengthLimitingTextInputFormatter(maxLength)],
              keyboardType: keyboardType,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: AppTextStyles.body.copyWith(color: colors.textPrimary),
              textInputAction: textInputAction,
            ),
          ),
        ],
      ),
    );
  }
}
