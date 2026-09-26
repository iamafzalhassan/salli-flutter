import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/scratch_card.dart';
import 'scratch_surface.dart';

class ScratchSheet extends StatelessWidget {
  const ScratchSheet({super.key, required this.card});

  static const double _surfaceSize = 240;

  final ScratchCard card;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final prize = card.prize;
    final isWin = card.isWin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.tr(LocaleKeys.rewardsScratchTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          context.tr(LocaleKeys.rewardsScratchFrom, args: [card.source]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox.square(
              dimension: _surfaceSize,
              child: ScratchSurface(
                cover: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, color: colors.onAccent, size: AppSpacing.iconLg),
                    const SizedBox(height: AppSpacing.sm),
                    Text(context.tr(LocaleKeys.rewardsScratchHint), maxLines: 1, style: AppTextStyles.label.copyWith(color: colors.onAccent)),
                  ],
                ),
                coverColor: colors.accent,
                child: ColoredBox(
                  color: colors.surfaceRaised,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isWin ? Icons.savings_rounded : Icons.sentiment_neutral_rounded, color: isWin ? colors.success : colors.textSecondary, size: AppSpacing.iconLg),
                        const SizedBox(height: AppSpacing.md),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isWin && prize != null ? context.tr(LocaleKeys.rewardsWon, args: [LkrFormat.withSymbol(prize, context.tr(LocaleKeys.currencySymbol))]) : context.tr(LocaleKeys.rewardsNoWin),
                            maxLines: 1,
                            style: AppTextStyles.title,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.tr(isWin ? LocaleKeys.rewardsWonBody : LocaleKeys.rewardsNoWinBody),
                          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: context.tr(LocaleKeys.resultDone), onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
