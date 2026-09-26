import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/summary_row_skeleton.dart';

class AccountSkeleton extends StatelessWidget {
  const AccountSkeleton({super.key});

  static const double _bodyLineFactor = 0.8;
  static const double _limitsTitleWidth = 160;
  static const double _statusFactor = 0.5;
  static const double _usageLabelWidth = 64;
  static const double _usageValueWidth = 120;

  static const int _detailRows = 4;
  static const int _usageBars = 2;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: SectionHeader(title: context.tr(LocaleKeys.accountDetails))),
          const Skeleton.circle(size: AppSpacing.touchTarget),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
        child: Column(children: [for (var index = 0; index < _detailRows; index++) const SummaryRowSkeleton()]),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.accountVerification)),
      const SizedBox(height: AppSpacing.sm),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Skeleton.circle(size: AppSpacing.iconMd),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: _statusFactor,
                    child: Skeleton.text(textStyle: AppTextStyles.bodyStrong),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Skeleton.text(textStyle: AppTextStyles.body),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: _bodyLineFactor,
              child: Skeleton.text(textStyle: AppTextStyles.body),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      const Skeleton.text(textStyle: AppTextStyles.title, width: _limitsTitleWidth),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        child: Column(
          children: [
            const SummaryRowSkeleton(),
            for (var index = 0; index < _usageBars; index++) ...[
              SizedBox(height: index == 0 ? AppSpacing.md : AppSpacing.lg),
              const Row(
                children: [
                  Skeleton.text(textStyle: AppTextStyles.label, width: _usageLabelWidth),
                  Spacer(),
                  Skeleton.text(textStyle: AppTextStyles.caption, width: _usageValueWidth),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Skeleton(radius: AppRadius.pill, height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    ],
  );
}
