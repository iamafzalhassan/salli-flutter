import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/language_option.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = AppLanguage.fromLocale(context.locale);
    return Scaffold(
      body: SafeArea(
        child: FillScrollView(
          children: [
            const SizedBox(height: AppSpacing.xxxl),
            Text(context.tr(LocaleKeys.languageTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(context.tr(LocaleKeys.languageSubtitle), style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            for (final language in AppLanguage.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: LanguageOption(isSelected: language == selected, language: language, onSelected: () => context.setLocale(language.locale)),
              ),
            const Spacer(),
            AppButton(label: context.tr(LocaleKeys.commonContinue), onPressed: () => unawaited(context.push<void>(AppRoutes.welcome))),
          ],
        ),
      ),
    );
  }
}
