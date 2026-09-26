import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/skeleton.dart';

class RequestTileSkeleton extends StatelessWidget {
  const RequestTileSkeleton({super.key});

  static const double _amountWidth = 88;
  static const double _nameFactor = 0.6;
  static const double _noteFactor = 0.4;
  static const double _statusWidth = 48;

  static const int _actionCount = 2;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Skeleton.circle(size: AppSpacing.touchTarget),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: _nameFactor,
                    child: Skeleton.text(textStyle: AppTextStyles.bodyStrong),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  FractionallySizedBox(
                    widthFactor: _noteFactor,
                    child: Skeleton.text(textStyle: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Skeleton.text(textStyle: AppTextStyles.amount, width: _amountWidth),
                SizedBox(height: AppSpacing.xxs),
                Skeleton.text(textStyle: AppTextStyles.caption, width: _statusWidth),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var index = 0; index < _actionCount; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Skeleton(radius: AppRadius.md, height: AppSpacing.controlHeight),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}
