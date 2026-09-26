import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_refresh_view.dart';
import '../../../../core/widgets/app_share.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tile_skeleton.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../cubits/activity_cubit.dart';
import '../cubits/activity_state.dart';
import '../widgets/transaction_filter_sheet.dart';
import '../widgets/transaction_tile.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  static const double _amountSkeletonWidth = 88;
  static const double _daySkeletonWidth = 72;
  static const double _loadMoreExtent = 480;

  static const int _monthDigits = 2;
  static const int _skeletonRows = 8;
  static const int _statementMonths = 6;

  static const String _statementExtension = '.pdf';
  static const String _statementStem = 'salli-statement-';
  static const String _statementType = 'application/pdf';

  static Future<void> _exportStatement(BuildContext context) async {
    final cubit = context.read<ActivityCubit>();
    final now = DateTime.now();
    final months = [for (var offset = 0; offset < _statementMonths; offset++) DateTime(now.year, now.month - offset)];
    final month = await showAppSheet<DateTime>(
      context,
      child: OptionSheet<DateTime>(
        options: [for (final month in months) (leading: const IconAvatar(icon: Icons.calendar_month_rounded, isAccent: false), subtitle: null, title: context.monthLabel(month), value: month)],
        title: context.tr(LocaleKeys.activityStatementTitle),
      ),
    );
    if (month == null || !context.mounted) return;
    final result = await cubit.exportStatement(month, DateTime(month.year, month.month + 1));
    if (!context.mounted) return;
    switch (result) {
      case Ok(:final value):
        await shareContent(
          context,
          files: [XFile.fromData(value, mimeType: _statementType, name: '$_statementStem${month.year}-${month.month.toString().padLeft(_monthDigits, '0')}$_statementExtension')],
          text: context.tr(LocaleKeys.activityStatementShare, args: [context.monthLabel(month)]),
        );
      case Err(:final failure):
        showAppSnackBar(context, context.failureMessage(failure));
    }
  }

  static Future<void> _openFilter(BuildContext context, TransactionFilter filter) async {
    final cubit = context.read<ActivityCubit>();
    final result = await showAppSheet<TransactionFilter>(context, child: TransactionFilterSheet(filter: filter));
    if (result != null) await cubit.applyFilter(result);
  }

  static bool _onScroll(BuildContext context, ScrollNotification notification) {
    if (notification.metrics.extentAfter < _loadMoreExtent) unawaited(context.read<ActivityCubit>().loadMore());
    return false;
  }

  static List<Widget> _rows(BuildContext context, ActivityState state) {
    final colors = context.colors;
    final banner = state.pendingRequests == 0
        ? const <Widget>[]
        : [
            AppListTile(
              leading: const IconAvatar(icon: Icons.inbox_rounded),
              onPressed: () => unawaited(context.push<void>(AppRoutes.requests)),
              subtitle: context.tr(LocaleKeys.activityRequestsBody),
              title: context.plural(LocaleKeys.activityRequestsWaiting, state.pendingRequests),
            ),
            const SizedBox(height: AppSpacing.md),
          ];
    return [
      ...banner,
      ...switch (state.status) {
        ActivityStatus.loading => [
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xs),
            child: Skeleton.text(textStyle: AppTextStyles.overline, width: _daySkeletonWidth),
          ),
          for (var index = 0; index < _skeletonRows; index++)
            const TileSkeleton(
              trailing: Skeleton.text(textStyle: AppTextStyles.amount, width: _amountSkeletonWidth),
            ),
        ],
        ActivityStatus.failure => [
          StatusMessage(
            actionLabel: context.tr(LocaleKeys.commonRetry),
            body: context.failureMessage(state.failure!),
            icon: Icons.cloud_off_rounded,
            onAction: context.read<ActivityCubit>().load,
            title: context.tr(LocaleKeys.commonErrorTitle),
          ),
        ],
        ActivityStatus.ready when state.items.isEmpty && !state.filter.isEmpty => [StatusMessage(body: context.tr(LocaleKeys.activityNoMatchesBody), icon: Icons.search_off_rounded, title: context.tr(LocaleKeys.activityNoMatchesTitle))],
        ActivityStatus.ready when state.items.isEmpty => [StatusMessage(body: context.tr(LocaleKeys.activityEmptyBody), icon: Icons.receipt_long_rounded, title: context.tr(LocaleKeys.activityEmptyTitle))],
        ActivityStatus.ready => [
          for (final (index, transaction) in state.items.indexed) ...[
            if (index == 0 || !_isSameDay(state.items[index - 1], transaction))
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs, top: index == 0 ? 0 : AppSpacing.xl),
                child: Text(context.dayLabel(transaction.createdAt).toUpperCase(), maxLines: 1, style: AppTextStyles.overline.copyWith(color: colors.textSecondary)),
              ),
            TransactionTile(transaction: transaction),
          ],
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: AppLoader()),
            ),
        ],
      },
    ];
  }

  static bool _isSameDay(WalletTransaction first, WalletTransaction second) => DateUtils.isSameDay(first.createdAt.toLocal(), second.createdAt.toLocal());

  @override
  Widget build(BuildContext context) => BlocBuilder<ActivityCubit, ActivityState>(
    builder: (context, state) {
      final cubit = context.read<ActivityCubit>();
      final rows = _rows(context, state);
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.lg, AppSpacing.screenPadding, AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(context.tr(LocaleKeys.activityTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline),
                    ),
                    AppIconButton(icon: Icons.insights_rounded, onPressed: () => unawaited(context.push<void>(AppRoutes.insights)), semanticLabel: context.tr(LocaleKeys.activityInsights)),
                    const SizedBox(width: AppSpacing.sm),
                    AppIconButton(icon: Icons.description_rounded, onPressed: state.isExporting ? null : () => unawaited(_exportStatement(context)), semanticLabel: context.tr(LocaleKeys.activityStatement)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(hint: context.tr(LocaleKeys.activitySearchHint), icon: Icons.search_rounded, onChanged: cubit.search, textInputAction: TextInputAction.search),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppIconButton(icon: state.filter.hasCriteria ? Icons.filter_alt_rounded : Icons.tune_rounded, onPressed: () => unawaited(_openFilter(context, state.filter)), semanticLabel: context.tr(LocaleKeys.activityFilter)),
                  ],
                ),
              ),
              if (state.filter.hasCriteria)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.md),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppChip(
                      icon: Icons.close_rounded,
                      isSelected: true,
                      label: context.tr(LocaleKeys.activityClearFilters),
                      onPressed: () => unawaited(cubit.applyFilter(TransactionFilter(query: state.filter.query))),
                    ),
                  ),
                ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => _onScroll(context, notification),
                  child: AppRefreshView(
                    onRefresh: cubit.load,
                    padding: const EdgeInsets.only(bottom: AppSpacing.navClearance, left: AppSpacing.screenPadding, right: AppSpacing.screenPadding),
                    children: rows,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
