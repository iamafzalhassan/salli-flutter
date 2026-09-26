import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/security/biometric_prompt_text.dart';
import '../../../../core/security/secure_clipboard.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/amount_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pin_entry_sheet.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/settings_toggle.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/usage_bar.dart';
import '../cubits/card_cubit.dart';
import '../cubits/card_state.dart';
import '../widgets/virtual_card_view.dart';

class CardPage extends StatelessWidget {
  const CardPage({super.key, this.isSandbox = false});

  static const int _maxLimitRupees = 500000;

  final bool isSandbox;

  static Future<void> _toggleDetails(BuildContext context, CardState state) async {
    final cubit = context.read<CardCubit>();
    if (state.secrets != null) return cubit.hide();
    if (state.canUseBiometrics) {
      final failure = await cubit.reveal(BiometricAuthorization(BiometricPromptText(cancel: context.tr(LocaleKeys.biometricUsePin), title: context.tr(LocaleKeys.cardRevealPrompt))));
      if (failure == null || !CardCubit.pinFallbackCodes.contains(failure.code) || !context.mounted) return;
    }
    final pin = await showAppSheet<String>(
      context,
      child: PinEntrySheet(body: context.tr(LocaleKeys.cardRevealPinBody), title: context.tr(LocaleKeys.cardRevealPrompt)),
    );
    if (pin != null) await cubit.reveal(PinAuthorization(pin));
  }

  static Future<void> _changeLimit(BuildContext context, Money current) async {
    final cubit = context.read<CardCubit>();
    final limit = await showAppSheet<Money>(
      context,
      child: AmountSheet(confirmLabel: context.tr(LocaleKeys.commonSave), initial: current, limit: const Money.rupees(_maxLimitRupees), title: context.tr(LocaleKeys.cardLimitTitle)),
    );
    if (limit != null) await cubit.setLimit(limit);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CardCubit, CardState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<CardCubit>();
      final card = state.card;
      final secrets = state.secrets;
      final symbol = context.tr(LocaleKeys.currencySymbol);
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            physics: const BouncingScrollPhysics(),
            children: [
              PageHeader(title: context.tr(LocaleKeys.cardTitle)),
              const SizedBox(height: AppSpacing.xl),
              if (card == null)
                state.status == CardLoadStatus.failure
                    ? StatusMessage(actionLabel: context.tr(LocaleKeys.commonRetry), body: context.failureMessage(state.failure!), icon: Icons.cloud_off_rounded, onAction: cubit.load, title: context.tr(LocaleKeys.commonErrorTitle))
                    : const Column(
                        children: [
                          AspectRatio(
                            aspectRatio: VirtualCardView.aspectRatio,
                            child: Skeleton(radius: AppRadius.xl, height: double.infinity),
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: Skeleton(radius: AppRadius.md, height: AppSpacing.controlHeight),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Skeleton(radius: AppRadius.md, height: AppSpacing.controlHeight),
                              ),
                            ],
                          ),
                        ],
                      )
              else ...[
                VirtualCardView(card: card, secrets: secrets),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        isLoading: state.isBusy && secrets == null,
                        label: context.tr(secrets == null ? LocaleKeys.cardShowDetails : LocaleKeys.cardHideDetails),
                        onPressed: card.isFrozen ? null : () => unawaited(_toggleDetails(context, state)),
                        variant: AppButtonVariant.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(label: context.tr(LocaleKeys.cardCopyNumber), onPressed: secrets == null ? null : () => unawaited(SecureClipboard.copy(secrets.number)), variant: AppButtonVariant.secondary),
                    ),
                  ],
                ),
                if (secrets != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr(LocaleKeys.cardRevealNote),
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
                FailureText(failure: state.failure, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                SettingsToggle(
                  icon: Icons.ac_unit_rounded,
                  isBusy: state.isBusy && secrets != null,
                  onChanged: (isFrozen) => unawaited(cubit.setFrozen(isFrozen)),
                  subtitle: context.tr(LocaleKeys.cardFreezeBody),
                  title: context.tr(LocaleKeys.cardFreeze),
                  value: card.isFrozen,
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsRow(icon: Icons.speed_rounded, onPressed: () => unawaited(_changeLimit(context, card.spendLimit)), title: context.tr(LocaleKeys.cardLimit), value: LkrFormat.withSymbol(card.spendLimit, symbol)),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: UsageBar(label: context.tr(LocaleKeys.cardSpent), limit: card.spendLimit, used: card.spent),
                ),
                if (isSandbox) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: context.tr(LocaleKeys.cardTestPurchase), onPressed: state.isBusy ? null : () => unawaited(cubit.testPurchase()), variant: AppButtonVariant.secondary),
                ],
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: context.tr(LocaleKeys.cardTransactions)),
                const SizedBox(height: AppSpacing.sm),
                if (state.transactions.isEmpty)
                  Text(context.tr(LocaleKeys.cardNoTransactions), style: AppTextStyles.body.copyWith(color: colors.textSecondary))
                else
                  for (final transaction in state.transactions)
                    AppListTile(
                      leading: const IconAvatar(icon: Icons.credit_card_rounded, isAccent: false),
                      subtitle: context.momentLabel(transaction.createdAt),
                      title: transaction.merchant,
                      trailing: Text(LkrFormat.signed(transaction.amount, symbol), maxLines: 1, style: AppTextStyles.amount),
                    ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
