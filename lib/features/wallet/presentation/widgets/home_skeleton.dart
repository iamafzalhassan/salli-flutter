import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/tile_skeleton.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  static const double _amountWidth = 88;
  static const double _balanceLabelWidth = 64;
  static const double _balanceToggle = AppSpacing.iconSm + AppSpacing.xs * 2;
  static const double _balanceWidth = 220;
  static const double _chipWidth = 112;
  static const double _greetingWidth = 96;
  static const double _nameWidth = 140;
  static const double _sectionActionWidth = 48;
  static const double _sectionTitleWidth = 72;

  static const int _actionCount = 4;
  static const int _chipCount = 3;
  static const int _rowCount = 4;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Skeleton.circle(size: AppSpacing.touchTarget),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.text(textStyle: AppTextStyles.caption, width: _greetingWidth),
                SizedBox(height: AppSpacing.xxs),
                Skeleton.text(textStyle: AppTextStyles.title, width: _nameWidth),
              ],
            ),
          ),
          Skeleton.circle(size: AppSpacing.touchTarget),
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      const Row(
        children: [
          Skeleton.text(textStyle: AppTextStyles.label, width: _balanceLabelWidth),
          SizedBox(width: AppSpacing.xs),
          Skeleton.circle(size: _balanceToggle),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      const Skeleton.text(textStyle: AppTextStyles.balance, width: _balanceWidth),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        runSpacing: AppSpacing.sm,
        spacing: AppSpacing.sm,
        children: [for (var index = 0; index < _chipCount; index++) const Skeleton(radius: AppRadius.pill, height: AppSpacing.touchTarget, width: _chipWidth)],
      ),
      const SizedBox(height: AppSpacing.xl),
      Row(
        children: [
          for (var index = 0; index < _actionCount; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Skeleton(radius: AppRadius.lg, height: double.infinity),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      const Row(
        children: [
          Skeleton.text(textStyle: AppTextStyles.title, width: _sectionTitleWidth),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Skeleton.text(textStyle: AppTextStyles.label, width: _sectionActionWidth),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      for (var index = 0; index < _rowCount; index++)
        const TileSkeleton(
          trailing: Skeleton.text(textStyle: AppTextStyles.amount, width: _amountWidth),
        ),
    ],
  );
}
