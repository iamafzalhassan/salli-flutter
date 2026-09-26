import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../domain/entities/referral.dart';

class ReferralCard extends StatelessWidget {
  const ReferralCard({super.key, this.isClaiming = false, required this.referral, this.onClaim, this.onCopy, this.onShare});

  final bool isClaiming;

  final Referral referral;

  final VoidCallback? onClaim;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconAvatar(icon: Icons.group_add_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr(LocaleKeys.rewardsReferralTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      context.tr(LocaleKeys.rewardsReferralBody, args: [LkrFormat.withSymbol(referral.reward, context.tr(LocaleKeys.currencySymbol))]),
                      style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), color: colors.surfaceRaised),
            padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referral.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(fontFeatures: AppTextStyles.tabular),
                  ),
                ),
                AppIconButton(icon: Icons.copy_rounded, onPressed: onCopy, semanticLabel: context.tr(LocaleKeys.rewardsCopyCode)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.plural(LocaleKeys.rewardsReferralJoined, referral.joinedCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: context.tr(LocaleKeys.rewardsShare), onPressed: onShare),
          if (referral.canClaim) ...[const SizedBox(height: AppSpacing.md), AppButton(isLoading: isClaiming, label: context.tr(LocaleKeys.rewardsHaveCode), onPressed: onClaim, variant: AppButtonVariant.secondary)],
        ],
      ),
    );
  }
}
