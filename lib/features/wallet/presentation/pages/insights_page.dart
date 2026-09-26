import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/summary_row.dart';
import '../../domain/entities/monthly_insights.dart';
import '../cubits/insights_cubit.dart';
import '../cubits/insights_state.dart';
import '../widgets/insights_skeleton.dart';
import '../widgets/spending_donut.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  static const double _chartSize = 200;
  static const double _chartStroke = 22;

  static List<Widget> _content(BuildContext context, MonthlyInsights insights) {
    final colors = context.colors;
    final symbol = context.tr(LocaleKeys.currencySymbol);
    final palette = _palette(colors);
    final percent = NumberFormat.percentPattern(context.locale.toLanguageTag());
    if (insights.spending.isZero && insights.income.isZero) {
      return [StatusMessage(body: context.tr(LocaleKeys.insightsEmptyBody), icon: Icons.pie_chart_outline_rounded, title: context.tr(LocaleKeys.insightsEmptyTitle))];
    }
    final change = insights.spending - insights.previousSpending;
    return [
      Center(
        child: SizedBox.square(
          dimension: _chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SpendingDonut(
                key: ValueKey(insights.month),
                segments: [for (final (index, category) in insights.categories.indexed) (color: palette[index % palette.length], fraction: category.amount.cents / insights.spending.cents)],
                strokeWidth: _chartStroke,
                trackColor: colors.surfaceRaised,
              ),
              Padding(
                padding: const EdgeInsets.all(_chartStroke + AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(LocaleKeys.insightsSpent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(LkrFormat.withSymbol(insights.spending, symbol), maxLines: 1, style: AppTextStyles.title.copyWith(fontFeatures: AppTextStyles.tabular)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        change.isZero ? context.tr(LocaleKeys.insightsSame) : context.tr(change.isPositive ? LocaleKeys.insightsMore : LocaleKeys.insightsLess, args: [LkrFormat.withSymbol(change.abs(), symbol)]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
        child: Column(
          children: [
            SummaryRow(label: context.tr(LocaleKeys.insightsMoneyIn), value: LkrFormat.withSymbol(insights.income, symbol)),
            SummaryRow(label: context.tr(LocaleKeys.insightsMoneyOut), value: LkrFormat.withSymbol(insights.spending, symbol)),
          ],
        ),
      ),
      if (insights.categories.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: context.tr(LocaleKeys.insightsCategories)),
        const SizedBox(height: AppSpacing.sm),
        for (final (index, category) in insights.categories.indexed)
          AppListTile(
            leading: Container(
              decoration: BoxDecoration(color: colors.surfaceRaised, shape: BoxShape.circle),
              height: AppSpacing.touchTarget,
              width: AppSpacing.touchTarget,
              child: Icon(CategoryIcons.of(category.category), color: palette[index % palette.length], size: AppSpacing.iconSm),
            ),
            subtitle: context.plural(LocaleKeys.insightsPayments, category.count),
            title: context.tr('${LocaleKeys.insightCategoryPrefix}.${category.category}'),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(LkrFormat.withSymbol(category.amount, symbol), maxLines: 1, style: AppTextStyles.amount),
                Text(percent.format(category.amount.cents / insights.spending.cents), maxLines: 1, style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
      ],
    ];
  }

  static List<Color> _palette(AppColors colors) => [colors.accentInk, colors.success, colors.warning, colors.danger, colors.textSecondary, colors.textPrimary];

  @override
  Widget build(BuildContext context) => BlocBuilder<InsightsCubit, InsightsState>(
    builder: (context, state) {
      final cubit = context.read<InsightsCubit>();
      final insights = state.insights;
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            physics: const BouncingScrollPhysics(),
            children: [
              PageHeader(title: context.tr(LocaleKeys.insightsTitle)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  AppIconButton(icon: Icons.chevron_left_rounded, onPressed: () => unawaited(cubit.previousMonth()), semanticLabel: context.tr(LocaleKeys.insightsPreviousMonth)),
                  Expanded(
                    child: Text(context.monthLabel(state.month), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title, textAlign: TextAlign.center),
                  ),
                  AppIconButton(icon: Icons.chevron_right_rounded, onPressed: state.canGoForward ? () => unawaited(cubit.nextMonth()) : null, semanticLabel: context.tr(LocaleKeys.insightsNextMonth)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (insights != null)
                ..._content(context, insights)
              else if (state.status == InsightsStatus.failure)
                StatusMessage(actionLabel: context.tr(LocaleKeys.commonRetry), body: context.failureMessage(state.failure!), icon: Icons.cloud_off_rounded, onAction: cubit.load, title: context.tr(LocaleKeys.commonErrorTitle))
              else
                const InsightsSkeleton(chartSize: _chartSize, chartStroke: _chartStroke),
            ],
          ),
        ),
      );
    },
  );
}
