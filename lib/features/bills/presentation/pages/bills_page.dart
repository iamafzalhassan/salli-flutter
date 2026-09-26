import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/action_tile.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_refresh_view.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pin_entry_sheet.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/text_entry_sheet.dart';
import '../../../../core/widgets/tile_skeleton.dart';
import '../../../payments/domain/entities/bill_category.dart';
import '../../domain/entities/bill_account_draft.dart';
import '../../domain/entities/bill_schedule.dart';
import '../../domain/entities/biller.dart';
import '../../domain/entities/saved_biller.dart';
import '../../domain/entities/schedule_run_status.dart';
import '../cubits/bills_cubit.dart';
import '../cubits/bills_state.dart';
import '../widgets/biller_picker_sheet.dart';
import '../widgets/saved_biller_sheet.dart';
import '../widgets/schedule_sheet.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  static const int _categoryColumns = 3;
  static const int _nicknameLength = 30;
  static const int _skeletonCategoryRows = 2;
  static const int _skeletonRows = 3;

  static const String _separator = ' · ';

  static List<Widget> _content(BuildContext context, BillsState state) {
    final colors = context.colors;
    final cubit = context.read<BillsCubit>();
    if (state.status == BillsStatus.loading) {
      return [
        SectionHeader(title: context.tr(LocaleKeys.billsSaved)),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < _skeletonRows; index++) const TileSkeleton(trailing: Skeleton.circle(size: AppSpacing.touchTarget)),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: context.tr(LocaleKeys.billsCategories)),
        const SizedBox(height: AppSpacing.md),
        for (var row = 0; row < _skeletonCategoryRows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                for (var index = 0; index < _categoryColumns; index++) ...[
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
          ),
      ];
    }
    if (state.status == BillsStatus.failure) {
      return [StatusMessage(actionLabel: context.tr(LocaleKeys.commonRetry), body: context.failureMessage(state.failure!), icon: Icons.cloud_off_rounded, onAction: cubit.load, title: context.tr(LocaleKeys.commonErrorTitle))];
    }
    final categories = [
      for (final category in BillCategory.values)
        if (state.billers.any((biller) => biller.category == category)) category,
    ];
    return [
      if (state.schedules.isNotEmpty) ...[
        SectionHeader(title: context.tr(LocaleKeys.billsUpcoming)),
        const SizedBox(height: AppSpacing.sm),
        for (final (index, schedule) in state.schedules.indexed)
          Entrance(
            index: index,
            child: AppListTile(
              leading: IconAvatar(icon: CategoryIcons.of(schedule.savedBiller.biller.category.name)),
              onPressed: () => unawaited(context.push<void>(AppRoutes.billAccount, extra: BillAccountDraft.saved(schedule.savedBiller))),
              subtitle: _scheduleLine(context, schedule),
              title: schedule.savedBiller.displayName,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
      SectionHeader(title: context.tr(LocaleKeys.billsSaved)),
      const SizedBox(height: AppSpacing.sm),
      if (state.saved.isEmpty)
        Text(context.tr(LocaleKeys.billsNoSaved), style: AppTextStyles.body.copyWith(color: colors.textSecondary))
      else
        for (final saved in state.saved)
          AppListTile(
            leading: IconAvatar(icon: CategoryIcons.of(saved.biller.category.name), isAccent: false),
            onPressed: () => unawaited(context.push<void>(AppRoutes.billAccount, extra: BillAccountDraft.saved(saved))),
            subtitle: [saved.biller.name, saved.accountNumber].join(_separator),
            title: saved.displayName,
            trailing: AppIconButton(icon: Icons.more_horiz_rounded, onPressed: () => unawaited(_manage(context, saved, state.scheduleFor(saved))), semanticLabel: context.tr(LocaleKeys.billsManage)),
          ),
      FailureText(failure: state.actionFailure),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.billsCategories)),
      const SizedBox(height: AppSpacing.md),
      for (var start = 0; start < categories.length; start += _categoryColumns)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              for (var index = start; index < start + _categoryColumns; index++) ...[
                if (index > start) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: index < categories.length
                      ? ActionTile(
                          icon: CategoryIcons.of(categories[index].name),
                          label: context.tr('${LocaleKeys.billCategoryPrefix}.${categories[index].name}'),
                          onPressed: () => unawaited(_chooseBiller(context, categories[index], state.billers)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  static String _scheduleLine(BuildContext context, BillSchedule schedule) {
    final amountDue = schedule.amountDue;
    final date = context.dayLabel(schedule.nextRunAt);
    return [
      if (schedule.lastStatus == ScheduleRunStatus.failed) context.tr(LocaleKeys.billsAutopayFailed),
      if (amountDue != null && amountDue.isPositive) context.tr(LocaleKeys.billsAmountDue, args: [LkrFormat.withSymbol(amountDue, context.tr(LocaleKeys.currencySymbol))]),
      context.tr(schedule.autopay ? LocaleKeys.billsAutopayOn : LocaleKeys.billsReminderOn, args: [date]),
    ].join(_separator);
  }

  static Future<void> _manage(BuildContext context, SavedBiller saved, BillSchedule? schedule) async {
    final cubit = context.read<BillsCubit>();
    final action = await showAppSheet<SavedBillerAction>(
      context,
      child: SavedBillerSheet(hasSchedule: schedule != null, saved: saved),
    );
    if (!context.mounted) return;
    switch (action) {
      case SavedBillerAction.pay:
        await context.push<void>(AppRoutes.billAccount, extra: BillAccountDraft.saved(saved));
      case SavedBillerAction.rename:
        final nickname = await showAppSheet<String>(
          context,
          child: TextEntrySheet(confirmLabel: context.tr(LocaleKeys.billsSave), hint: saved.biller.name, initialValue: saved.nickname, maxLength: _nicknameLength, title: context.tr(LocaleKeys.billsRenameTitle)),
        );
        if (nickname != null) await cubit.rename(saved, nickname);
      case SavedBillerAction.schedule:
        await _schedule(context, saved);
      case SavedBillerAction.unschedule:
        if (schedule != null) await cubit.cancelSchedule(schedule);
      case SavedBillerAction.remove:
        final confirmed = await showAppSheet<bool>(
          context,
          child: ConfirmSheet(
            body: context.tr(LocaleKeys.billsRemoveBody),
            confirmLabel: context.tr(LocaleKeys.billsRemove),
            isDanger: true,
            title: context.tr(LocaleKeys.billsRemoveTitle, args: [saved.displayName]),
          ),
        );
        if (confirmed ?? false) await cubit.delete(saved);
      case null:
        return;
    }
  }

  static Future<void> _schedule(BuildContext context, SavedBiller saved) async {
    final cubit = context.read<BillsCubit>();
    final choice = await showAppSheet<(int, bool)>(context, child: const ScheduleSheet());
    if (choice == null || !context.mounted) return;
    final (day, autopay) = choice;
    if (!autopay) return cubit.schedule(saved, day);
    final pin = await showAppSheet<String>(
      context,
      child: PinEntrySheet(body: context.tr(LocaleKeys.billsAutopayPinBody), title: context.tr(LocaleKeys.billsAutopayPinTitle)),
    );
    if (pin != null) await cubit.schedule(saved, day, pin: pin);
  }

  static Future<void> _chooseBiller(BuildContext context, BillCategory category, List<Biller> billers) async {
    final biller = await showAppSheet<Biller>(
      context,
      child: BillerPickerSheet(
        billers: [
          for (final biller in billers)
            if (biller.category == category) biller,
        ],
        category: category,
      ),
    );
    if (biller != null && context.mounted) await context.push<void>(AppRoutes.billAccount, extra: BillAccountDraft(biller: biller));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<BillsCubit, BillsState>(
        builder: (context, state) => AppRefreshView(
          onRefresh: context.read<BillsCubit>().load,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            PageHeader(title: context.tr(LocaleKeys.billsTitle)),
            const SizedBox(height: AppSpacing.xl),
            ..._content(context, state),
          ],
        ),
      ),
    ),
  );
}
