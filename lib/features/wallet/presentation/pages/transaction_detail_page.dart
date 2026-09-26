import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/summary_row.dart';
import '../../../../core/widgets/text_entry_sheet.dart';
import '../../domain/entities/dispute_reason.dart';
import '../../domain/entities/timeline_status.dart';
import '../../domain/entities/transaction_detail.dart';
import '../../domain/entities/transaction_status.dart';
import '../cubits/transaction_detail_cubit.dart';
import '../cubits/transaction_detail_state.dart';
import '../widgets/timeline_row.dart';
import '../widgets/transaction_detail_skeleton.dart';
import '../widgets/transaction_icons.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key});

  static const int _maxDetailsLength = 280;

  static const Map<TransactionStatus, TimelineStatus> _statusSteps = {TransactionStatus.completed: TimelineStatus.completed, TransactionStatus.failed: TimelineStatus.failed, TransactionStatus.pending: TimelineStatus.pending};

  static List<Widget> _details(BuildContext context, TransactionDetailState state, TransactionDetail detail) {
    final colors = context.colors;
    final transaction = detail.transaction;
    final symbol = context.tr(LocaleKeys.currencySymbol);
    final phone = PhoneNumber.tryParse(detail.counterpartyPhone ?? '');
    final dispute = detail.dispute;
    final note = detail.note;
    final reference = detail.reference;
    final repeat = detail.repeatRecipient;
    final statusColor = switch (transaction.status) {
      TransactionStatus.completed => colors.success,
      TransactionStatus.failed => colors.danger,
      TransactionStatus.pending => colors.warning,
    };
    return [
      Center(
        child: IconAvatar(icon: TransactionIcons.of(transaction.type), isAccent: false, size: AppSpacing.iconHero),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(transaction.counterpartyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.xs),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(LkrFormat.signed(transaction.amount, symbol), maxLines: 1, style: AppTextStyles.balance.copyWith(color: transaction.isCredit ? colors.success : colors.textPrimary)),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        context.tr(TimelineRow.labels[_statusSteps[transaction.status]]!),
        maxLines: 1,
        style: AppTextStyles.label.copyWith(color: statusColor),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
        child: Column(
          children: [
            SummaryRow(label: context.tr(LocaleKeys.transactionDetailType), value: context.tr('${LocaleKeys.transactionPrefix}.${transaction.type.name}')),
            SummaryRow(
              label: context.tr(LocaleKeys.transactionDetailDate),
              value: context.tr(LocaleKeys.transactionDetailDateTime, args: [context.dateLabel(transaction.createdAt.toLocal()), context.timeLabel(transaction.createdAt)]),
            ),
            if (reference != null) SummaryRow(label: context.tr(LocaleKeys.transactionDetailReference), value: reference),
            if (phone != null) SummaryRow(label: context.tr(LocaleKeys.transactionDetailPhone), value: phone.display),
            if (detail.fee.isPositive) SummaryRow(label: context.tr(LocaleKeys.transactionDetailFee), value: LkrFormat.withSymbol(detail.fee, symbol)),
            if (note != null && note.isNotEmpty) SummaryRow(label: context.tr(LocaleKeys.transactionDetailNote), value: note),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.transactionDetailProgress)),
      const SizedBox(height: AppSpacing.md),
      for (final (index, step) in detail.timeline.indexed) TimelineRow(isLast: index == detail.timeline.length - 1, step: step),
      if (dispute != null) ...[
        const SizedBox(height: AppSpacing.lg),
        AppListTile(
          leading: const IconAvatar(icon: Icons.flag_rounded, isAccent: false),
          subtitle: context.tr(LocaleKeys.transactionDetailReportedBody, args: [dispute.reference]),
          title: context.tr('${LocaleKeys.disputePrefix}.${dispute.reason.name}'),
        ),
      ],
      FailureText(failure: state.failure, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.xl),
      if (repeat != null) ...[
        AppButton(
          label: context.tr(LocaleKeys.transactionDetailPayAgain),
          onPressed: () => unawaited(context.push<void>(AppRoutes.payAmount, extra: repeat)),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (dispute == null) AppButton(isLoading: state.isReporting, label: context.tr(LocaleKeys.transactionDetailReport), onPressed: () => unawaited(_report(context)), variant: AppButtonVariant.secondary),
    ];
  }

  static Future<void> _report(BuildContext context) async {
    final cubit = context.read<TransactionDetailCubit>();
    final reason = await showAppSheet<DisputeReason>(
      context,
      child: OptionSheet<DisputeReason>(
        options: [for (final reason in DisputeReason.values) (leading: null, subtitle: null, title: context.tr('${LocaleKeys.disputePrefix}.${reason.name}'), value: reason)],
        title: context.tr(LocaleKeys.transactionDetailReportTitle),
      ),
    );
    if (reason == null || !context.mounted) return;
    final details = await showAppSheet<String>(
      context,
      child: TextEntrySheet(
        confirmLabel: context.tr(LocaleKeys.transactionDetailReportSubmit),
        hint: context.tr(LocaleKeys.transactionDetailReportDetailsHint),
        maxLength: _maxDetailsLength,
        title: context.tr(LocaleKeys.transactionDetailReportDetailsTitle),
      ),
    );
    if (details != null) await cubit.report(reason, details.isEmpty ? null : details);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<TransactionDetailCubit, TransactionDetailState>(
    builder: (context, state) {
      final detail = state.detail;
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            physics: const BouncingScrollPhysics(),
            children: [
              PageHeader(title: context.tr(LocaleKeys.transactionDetailTitle)),
              const SizedBox(height: AppSpacing.xl),
              if (detail != null)
                ..._details(context, state, detail)
              else if (state.status == TransactionDetailStatus.failure)
                StatusMessage(
                  actionLabel: context.tr(LocaleKeys.commonRetry),
                  body: context.failureMessage(state.failure!),
                  icon: Icons.cloud_off_rounded,
                  onAction: context.read<TransactionDetailCubit>().load,
                  title: context.tr(LocaleKeys.commonErrorTitle),
                )
              else
                const TransactionDetailSkeleton(),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => showAppSnackBar(context, context.tr(LocaleKeys.transactionDetailReported)),
    listenWhen: (previous, current) => previous.detail != null && previous.detail?.dispute == null && current.detail?.dispute != null,
  );
}
