import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/animated_money.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../domain/entities/rewards_summary.dart';

class RewardsSummaryCard extends StatelessWidget {
  const RewardsSummaryCard({super.key, this.isRedeeming = false, required this.summary, this.onRedeem});

  final bool isRedeeming;

  final RewardsSummary summary;

  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final symbol = context.tr(LocaleKeys.currencySymbol);
    final canRedeem = summary.redeemablePoints > 0 && !isRedeeming;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), color: colors.accent),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(LocaleKeys.rewardsCashbackTotal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(color: colors.onAccent),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedMoney(
            money: summary.cashback,
            style: AppTextStyles.balance.copyWith(color: colors.onAccent),
            symbol: symbol,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.plural(LocaleKeys.rewardsPoints, summary.points),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(color: colors.onAccent),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      summary.redeemablePoints > 0 ? context.tr(LocaleKeys.rewardsPointsWorth, args: [LkrFormat.withSymbol(summary.pointsValue, symbol)]) : context.tr(LocaleKeys.rewardsRedeemFrom, args: ['${summary.minRedeemPoints}']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: colors.onAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AnimatedOpacity(
                duration: AppMotion.fast,
                opacity: canRedeem || isRedeeming ? 1 : AppMotion.disabledOpacity,
                child: AppPressable(
                  onPressed: canRedeem ? onRedeem : null,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: colors.onAccent),
                    height: AppSpacing.touchTarget,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: isRedeeming ? const AppLoader() : Text(context.tr(LocaleKeys.rewardsRedeem), maxLines: 1, style: AppTextStyles.label.copyWith(color: colors.accent)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
