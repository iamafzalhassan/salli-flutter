import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/security/biometric_prompt_text.dart';
import '../../../../core/security/pin_policy.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_keypad.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../../../../core/widgets/biometric_key.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pin_dots.dart';
import '../../../../core/widgets/shake.dart';
import '../../../../core/widgets/summary_row.dart';
import '../../domain/entities/recipient.dart';
import '../cubits/review_cubit.dart';
import '../cubits/review_state.dart';
import '../widgets/recipient_header.dart';
import '../widgets/step_up_notice.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  static Widget _approval(BuildContext context, ReviewState state) {
    final colors = context.colors;
    final cubit = context.read<ReviewCubit>();
    return Column(
      key: const ValueKey(true),
      children: [
        Text(
          context.tr(LocaleKeys.reviewPinPrompt),
          style: AppTextStyles.label.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Shake(
          trigger: state.errorToken,
          child: PinDots(filled: state.pin.length, hasError: state.failure != null && state.pin.isEmpty, length: PinPolicy.length),
        ),
        FailureText(failure: state.failure, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        AppKeypad(leading: state.canUseBiometrics ? const BiometricKey() : null, onBackspace: cubit.backspace, onDigit: cubit.digitEntered, onLeading: state.canUseBiometrics ? () => unawaited(cubit.useBiometrics(_prompt(context))) : null),
        const SizedBox(height: AppSpacing.lg),
        AppButton(isLoading: state.isSubmitting, label: context.tr(LocaleKeys.commonConfirm), onPressed: state.pin.length == PinPolicy.length ? () => unawaited(cubit.confirm()) : null),
        const SizedBox(height: AppSpacing.sm),
        AppTextButton(label: context.tr(LocaleKeys.commonCancel), onPressed: state.isSubmitting ? null : cubit.cancelAuthorization),
      ],
    );
  }

  static BiometricPromptText _prompt(BuildContext context) => BiometricPromptText(cancel: context.tr(LocaleKeys.biometricUsePin), title: context.tr(LocaleKeys.biometricApprove));

  @override
  Widget build(BuildContext context) => BlocConsumer<ReviewCubit, ReviewState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<ReviewCubit>();
      final draft = cubit.draft;
      final symbol = context.tr(LocaleKeys.currencySymbol);
      final note = draft.note;
      final fee = draft.recipient.fee;
      final total = draft.amount + fee;
      return PopScope(
        canPop: !state.isSubmitting,
        child: Scaffold(
          body: SafeArea(
            child: FillScrollView(
              children: [
                PageHeader(title: context.tr(LocaleKeys.reviewTitle)),
                const SizedBox(height: AppSpacing.xl),
                RecipientHeader(recipient: draft.recipient),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
                  child: Column(
                    children: [
                      SummaryRow(label: context.tr(LocaleKeys.reviewAmount), value: LkrFormat.withSymbol(draft.amount, symbol)),
                      SummaryRow(label: context.tr(LocaleKeys.reviewFee), value: fee.isZero ? context.tr(LocaleKeys.reviewFree) : LkrFormat.withSymbol(fee, symbol)),
                      if (note != null) SummaryRow(label: context.tr(LocaleKeys.reviewNote), value: note),
                      Divider(color: colors.border, height: AppSpacing.lg, thickness: AppSpacing.hairline),
                      SummaryRow(isEmphasized: true, label: context.tr(LocaleKeys.reviewTotal), value: LkrFormat.withSymbol(total, symbol)),
                    ],
                  ),
                ),
                if (state.stepUpReasons.isNotEmpty) ...[const SizedBox(height: AppSpacing.lg), StepUpNotice(reasons: state.stepUpReasons)],
                const Spacer(),
                const SizedBox(height: AppSpacing.xl),
                AnimatedSwitcher(
                  duration: AppMotion.base,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(sizeFactor: animation, child: child),
                  ),
                  child: state.isAuthorizing
                      ? _approval(context, state)
                      : Column(
                          key: const ValueKey(false),
                          children: [
                            FailureText(failure: state.failure, textAlign: TextAlign.center),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: state.isCoolingOff
                                  ? context.tr(LocaleKeys.reviewCoolingOff, args: ['${state.coolingOffSeconds}'])
                                  : context.tr(
                                      switch (draft.recipient) {
                                        TopUpRecipient() => LocaleKeys.reviewAddMoney,
                                        WithdrawalRecipient() => LocaleKeys.reviewWithdraw,
                                        _ => LocaleKeys.reviewPay,
                                      },
                                      args: [LkrFormat.withSymbol(total, symbol)],
                                    ),
                              onPressed: state.isCoolingOff ? null : () => unawaited(cubit.authorize(_prompt(context))),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    listener: (context, state) => context.go(AppRoutes.payDone, extra: state.receipt),
    listenWhen: (previous, current) => current.receipt != null && previous.receipt == null,
  );
}
