import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/skeleton.dart';

class SplitTileSkeleton extends StatelessWidget {
  const SplitTileSkeleton({super.key});

  static const double _amountWidth = 88;
  static const double _detailFactor = 0.5;
  static const double _shareAmountWidth = 72;
  static const double _shareNameFactor = 0.4;
  static const double _titleFactor = 0.5;

  static const int _shareCount = 2;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: _titleFactor,
                child: Skeleton.text(textStyle: AppTextStyles.bodyStrong),
              ),
            ),
            Skeleton.text(textStyle: AppTextStyles.amount, width: _amountWidth),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        const FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: _detailFactor,
          child: Skeleton.text(textStyle: AppTextStyles.caption),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < _shareCount; index++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                Skeleton.circle(size: AppSpacing.iconXs),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: _shareNameFactor,
                    child: Skeleton.text(textStyle: AppTextStyles.label),
                  ),
                ),
                Skeleton.text(textStyle: AppTextStyles.label, width: _shareAmountWidth),
              ],
            ),
          ),
      ],
    ),
  );
}
