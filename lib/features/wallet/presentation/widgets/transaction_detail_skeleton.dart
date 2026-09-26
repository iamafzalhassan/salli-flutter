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
import '../../../../core/widgets/summary_row_skeleton.dart';

class TransactionDetailSkeleton extends StatelessWidget {
  const TransactionDetailSkeleton({super.key});

  static const double _amountWidth = 180;
  static const double _momentFactor = 0.3;
  static const double _nameWidth = 140;
  static const double _statusWidth = 72;
  static const double _stepFactor = 0.5;

  static const int _summaryRows = 3;
  static const int _timelineSteps = 2;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: Skeleton.circle(size: AppSpacing.iconHero)),
      const SizedBox(height: AppSpacing.md),
      const Center(
        child: Skeleton.text(textStyle: AppTextStyles.title, width: _nameWidth),
      ),
      const SizedBox(height: AppSpacing.xs),
      const Center(
        child: Skeleton.text(textStyle: AppTextStyles.balance, width: _amountWidth),
      ),
      const SizedBox(height: AppSpacing.xs),
      const Center(
        child: Skeleton.text(textStyle: AppTextStyles.label, width: _statusWidth),
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
        child: Column(children: [for (var index = 0; index < _summaryRows; index++) const SummaryRowSkeleton()]),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.transactionDetailProgress)),
      const SizedBox(height: AppSpacing.md),
      for (var index = 0; index < _timelineSteps; index++)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const SizedBox(height: AppSpacing.xs),
                const Skeleton.circle(size: AppSpacing.md),
                if (index < _timelineSteps - 1) Container(color: context.colors.border, height: AppSpacing.xxl, width: AppSpacing.xxs),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: _stepFactor,
                    child: Skeleton.text(textStyle: AppTextStyles.bodyStrong),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  FractionallySizedBox(
                    widthFactor: _momentFactor,
                    child: Skeleton.text(textStyle: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
          ],
        ),
      const SizedBox(height: AppSpacing.xl),
      const Skeleton(radius: AppRadius.md, height: AppSpacing.controlHeight),
    ],
  );
}
