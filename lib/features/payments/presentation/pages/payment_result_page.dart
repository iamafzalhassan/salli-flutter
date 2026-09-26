import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/animated_money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/success_mark.dart';
import '../../../../core/widgets/summary_row.dart';
import '../../domain/entities/payment_receipt.dart';
import '../../domain/entities/recipient.dart';

class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({super.key, required this.receipt});

  static const String _separator = ' · ';

  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final note = receipt.note;
    final recipient = receipt.recipient;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: FillScrollView(
            children: [
              const Spacer(),
              const Center(child: SuccessMark()),
              const SizedBox(height: AppSpacing.xl),
              Entrance(
                index: 4,
                child: Text(
                  context.tr(switch (recipient) {
                    TopUpRecipient() => LocaleKeys.resultAddedTitle,
                    WithdrawalRecipient() => LocaleKeys.resultWithdrawnTitle,
                    _ => LocaleKeys.resultTitle,
                  }),
                  style: AppTextStyles.headline,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Entrance(
                index: 5,
                child: Text(
                  context.tr(
                    switch (recipient) {
                      PersonRecipient() || BankRecipient() => LocaleKeys.resultBody,
                      MerchantRecipient() || BillRecipient() => LocaleKeys.resultPaidTo,
                      ReloadRecipient() => LocaleKeys.resultReloaded,
                      TopUpRecipient() => LocaleKeys.resultFrom,
                      WithdrawalRecipient() => LocaleKeys.resultTo,
                    },
                    args: [recipient.displayName],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: AnimatedMoney(
                  money: receipt.total,
                  style: AppTextStyles.balance.copyWith(color: colors.textPrimary),
                  symbol: context.tr(LocaleKeys.currencySymbol),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Entrance(
                index: 6,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
                  child: Column(
                    children: [
                      SummaryRow(label: context.tr(LocaleKeys.resultReference), value: receipt.reference),
                      SummaryRow(label: context.tr(LocaleKeys.resultDate), value: '${context.dayLabel(receipt.createdAt)}$_separator${context.timeLabel(receipt.createdAt)}'),
                      if (note != null) SummaryRow(label: context.tr(LocaleKeys.reviewNote), value: note),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              AppButton(label: context.tr(LocaleKeys.resultDone), onPressed: () => context.go(AppRoutes.home)),
            ],
          ),
        ),
      ),
    );
  }
}
