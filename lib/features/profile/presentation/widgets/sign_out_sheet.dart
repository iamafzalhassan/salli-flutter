import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';

class SignOutSheet extends StatelessWidget {
  const SignOutSheet({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.tr(LocaleKeys.profileSignOutTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.sm),
      Text(context.tr(LocaleKeys.profileSignOutBody), style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
      const SizedBox(height: AppSpacing.xl),
      Row(
        children: [
          Expanded(
            child: AppButton(label: context.tr(LocaleKeys.commonCancel), onPressed: () => Navigator.of(context).pop(false), variant: AppButtonVariant.secondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(label: context.tr(LocaleKeys.profileSignOut), onPressed: () => Navigator.of(context).pop(true), variant: AppButtonVariant.danger),
          ),
        ],
      ),
    ],
  );
}
