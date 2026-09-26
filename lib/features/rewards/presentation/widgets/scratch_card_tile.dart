import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../domain/entities/scratch_card.dart';

class ScratchCardTile extends StatelessWidget {
  const ScratchCardTile({super.key, this.isBusy = false, required this.card, this.onPressed});

  final bool isBusy;

  final ScratchCard card;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final prize = card.prize;
    final foreground = card.isScratched ? colors.textPrimary : colors.onAccent;
    final secondary = card.isScratched ? colors.textSecondary : colors.onAccent;
    return AppPressable(
      onPressed: card.isScratched ? null : onPressed,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), color: card.isScratched ? colors.surface : colors.accent),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBusy)
              const AppLoader()
            else
              Icon(
                switch (card) {
                  ScratchCard(isScratched: false) => Icons.auto_awesome_rounded,
                  ScratchCard(isWin: true) => Icons.savings_rounded,
                  _ => Icons.sentiment_neutral_rounded,
                },
                color: card.isWin ? colors.success : foreground,
                size: AppSpacing.iconMd,
              ),
            const Spacer(),
            Text(
              switch (prize) {
                null => context.tr(LocaleKeys.rewardsTapToScratch),
                final Money prize when prize.isPositive => LkrFormat.withSymbol(prize, context.tr(LocaleKeys.currencySymbol)),
                _ => context.tr(LocaleKeys.rewardsNoWin),
              },
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (prize?.isPositive ?? false ? AppTextStyles.amount : AppTextStyles.bodyStrong).copyWith(color: foreground),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              card.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}
