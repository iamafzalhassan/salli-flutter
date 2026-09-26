import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../localization/locale_keys.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_pressable.dart';
import 'selection_mark.dart';

class LanguageOption extends StatelessWidget {
  const LanguageOption({super.key, required this.isSelected, required this.language, required this.onSelected});

  final bool isSelected;

  final AppLanguage language;

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPressable(
      onPressed: onSelected,
      child: AnimatedContainer(
        curve: AppMotion.standard,
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? colors.accentInk : colors.border, width: AppSpacing.hairline),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: isSelected ? colors.surfaceRaised : colors.surface,
        ),
        duration: AppMotion.base,
        height: AppSpacing.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Text(context.tr('${LocaleKeys.languagePrefix}.${language.code}'), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
            ),
            SelectionMark(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}
