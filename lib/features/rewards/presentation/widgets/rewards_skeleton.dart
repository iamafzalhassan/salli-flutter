import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';

class RewardsSkeleton extends StatelessWidget {
  const RewardsSkeleton({super.key, required this.cardAspectRatio, required this.columns});

  static const double _balanceWidth = 160;
  static const double _bodyFactor = 0.8;
  static const double _codeFactor = 0.4;
  static const double _joinedWidth = 120;
  static const double _labelWidth = 120;
  static const double _pointsFactor = 0.5;
  static const double _redeemWidth = 88;
  static const double _titleFactor = 0.6;
  static const double _worthFactor = 0.4;

  static const int _cardCount = 4;

  final double cardAspectRatio;

  final int columns;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), color: context.colors.surface),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton.text(textStyle: AppTextStyles.label, width: _labelWidth),
              SizedBox(height: AppSpacing.xs),
              Skeleton.text(textStyle: AppTextStyles.balance, width: _balanceWidth),
              SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: _pointsFactor,
                          child: Skeleton.text(textStyle: AppTextStyles.bodyStrong),
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        FractionallySizedBox(
                          widthFactor: _worthFactor,
                          child: Skeleton.text(textStyle: AppTextStyles.caption),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Skeleton(radius: AppRadius.pill, height: AppSpacing.touchTarget, width: _redeemWidth),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.rewardsScratchCards)),
      const SizedBox(height: AppSpacing.md),
      GridView.count(
        childAspectRatio: cardAspectRatio,
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [for (var index = 0; index < _cardCount; index++) const Skeleton(radius: AppRadius.lg, height: double.infinity)],
      ),
      const SizedBox(height: AppSpacing.xl),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.circle(size: AppSpacing.touchTarget),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: _titleFactor,
                        child: Skeleton.text(textStyle: AppTextStyles.bodyStrong),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      Skeleton.text(textStyle: AppTextStyles.caption),
                      FractionallySizedBox(
                        widthFactor: _bodyFactor,
                        child: Skeleton.text(textStyle: AppTextStyles.caption),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.xs),
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: _codeFactor,
                      child: Skeleton.text(textStyle: AppTextStyles.title),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs),
                  child: Skeleton.circle(size: AppSpacing.touchTarget),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Skeleton.text(textStyle: AppTextStyles.caption, width: _joinedWidth),
            SizedBox(height: AppSpacing.lg),
            Skeleton(radius: AppRadius.md, height: AppSpacing.controlHeight),
          ],
        ),
      ),
    ],
  );
}
