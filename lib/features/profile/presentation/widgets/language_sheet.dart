import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/language_option.dart';

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  static Future<void> _select(BuildContext context, AppLanguage language) async {
    await context.setLocale(language.locale);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selected = AppLanguage.fromLocale(context.locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr(LocaleKeys.profileLanguage), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.lg),
        for (final language in AppLanguage.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: LanguageOption(isSelected: language == selected, language: language, onSelected: () => _select(context, language)),
          ),
      ],
    );
  }
}
