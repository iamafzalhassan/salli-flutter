import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_button.dart';

class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({super.key, this.isDanger = false, required this.body, required this.confirmLabel, required this.title});

  final bool isDanger;

  final String body;
  final String confirmLabel;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.sm),
      Text(body, style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
      const SizedBox(height: AppSpacing.xl),
      Row(
        children: [
          Expanded(
            child: AppButton(label: context.tr(LocaleKeys.commonCancel), onPressed: () => Navigator.of(context).pop(false), variant: AppButtonVariant.secondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(label: confirmLabel, onPressed: () => Navigator.of(context).pop(true), variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary),
          ),
        ],
      ),
    ],
  );
}
