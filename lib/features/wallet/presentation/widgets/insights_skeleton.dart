import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/summary_row_skeleton.dart';
import '../../../../core/widgets/tile_skeleton.dart';

class InsightsSkeleton extends StatelessWidget {
  const InsightsSkeleton({super.key, required this.chartSize, required this.chartStroke});

  static const double _amountWidth = 88;
  static const double _changeWidth = 180;
  static const double _percentWidth = 32;
  static const double _spentWidth = 48;
  static const double _totalWidth = 96;

  static const int _categoryRows = 3;
  static const int _summaryRows = 2;

  final double chartSize;
  final double chartStroke;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: SizedBox.square(
          dimension: chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Skeleton.circle(size: chartSize),
              Container(
                decoration: BoxDecoration(color: context.colors.background, shape: BoxShape.circle),
                height: chartSize - chartStroke * 2,
                width: chartSize - chartStroke * 2,
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Skeleton.text(textStyle: AppTextStyles.caption, width: _spentWidth),
                  SizedBox(height: AppSpacing.xxs),
                  Skeleton.text(textStyle: AppTextStyles.title, width: _totalWidth),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const Center(
        child: Skeleton.text(textStyle: AppTextStyles.caption, width: _changeWidth),
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
        child: Column(children: [for (var index = 0; index < _summaryRows; index++) const SummaryRowSkeleton()]),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.insightsCategories)),
      const SizedBox(height: AppSpacing.sm),
      for (var index = 0; index < _categoryRows; index++)
        const TileSkeleton(
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Skeleton.text(textStyle: AppTextStyles.amount, width: _amountWidth),
              Skeleton.text(textStyle: AppTextStyles.caption, width: _percentWidth),
            ],
          ),
        ),
    ],
  );
}
