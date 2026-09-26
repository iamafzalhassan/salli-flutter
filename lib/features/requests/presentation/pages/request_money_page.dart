import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/payment_link.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_keypad.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_share.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/decimal_key.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shake.dart';
import '../../../../core/widgets/success_mark.dart';
import '../../../payments/domain/entities/payee.dart';
import '../../../payments/domain/entities/payment_limits.dart';
import '../../domain/entities/money_request.dart';
import '../cubits/request_money_cubit.dart';
import '../cubits/request_money_state.dart';

class RequestMoneyPage extends StatelessWidget {
  const RequestMoneyPage({super.key});

  static List<Widget> _choosePerson(BuildContext context, RequestMoneyState state) {
    final cubit = context.read<RequestMoneyCubit>();
    final phone = state.phone;
    return [
      AppListTile(
        leading: const IconAvatar(icon: Icons.call_split_rounded),
        onPressed: () => unawaited(context.push<void>(AppRoutes.split)),
        subtitle: context.tr(LocaleKeys.requestSplitBody),
        title: context.tr(LocaleKeys.requestSplit),
      ),
      AppListTile(
        leading: const IconAvatar(icon: Icons.inbox_rounded, isAccent: false),
        onPressed: () => unawaited(context.push<void>(AppRoutes.requests)),
        subtitle: context.tr(LocaleKeys.requestYoursBody),
        title: context.tr(LocaleKeys.requestYours),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.requestFrom)),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        hint: context.tr(LocaleKeys.sendPhoneHint),
        icon: Icons.phone_iphone_rounded,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        keyboardType: TextInputType.phone,
        maxLength: PhoneNumber.maxInputDigits,
        onChanged: cubit.phoneChanged,
        onSubmitted: (_) => unawaited(cubit.submitPhone()),
      ),
      FailureText(failure: state.failure),
      if (phone != null) AppListTile(leading: const Avatar(), onPressed: () => unawaited(cubit.submitPhone()), title: phone.display, trailing: state.isLookingUp ? const AppLoader() : null),
      for (final payee in state.recents)
        AppListTile(
          leading: Avatar(name: payee.name),
          onPressed: () => cubit.choose(payee),
          subtitle: payee.phone.display,
          title: payee.displayName,
        ),
    ];
  }

  static List<Widget> _enterAmount(BuildContext context, RequestMoneyState state, Payee payee) {
    final colors = context.colors;
    final cubit = context.read<RequestMoneyCubit>();
    return [
      AppListTile(
        leading: Avatar(name: payee.name),
        onPressed: cubit.changePayee,
        subtitle: payee.phone.display,
        title: payee.displayName,
        trailing: Icon(Icons.edit_rounded, color: colors.textSecondary, size: AppSpacing.iconSm),
      ),
      const SizedBox(height: AppSpacing.xl),
      Shake(
        trigger: state.errorToken,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${context.tr(LocaleKeys.currencySymbol)} ${state.input.display}', maxLines: 1, style: AppTextStyles.balance.copyWith(color: state.input.isEmpty ? colors.textSecondary : colors.textPrimary)),
          ),
        ),
      ),
      FailureText(failure: state.failure, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(hint: context.tr(LocaleKeys.amountNote), icon: Icons.edit_note_rounded, maxLength: PaymentLimits.maxNoteLength, onChanged: cubit.noteChanged),
      const SizedBox(height: AppSpacing.lg),
      AppKeypad(leading: const DecimalKey(), onBackspace: cubit.backspace, onDigit: cubit.digitEntered, onLeading: cubit.decimalPoint),
      const SizedBox(height: AppSpacing.md),
      AppButton(isLoading: state.isSubmitting, label: context.tr(LocaleKeys.requestSend), onPressed: state.input.money.isPositive ? () => unawaited(cubit.send()) : null),
    ];
  }

  static List<Widget> _sent(BuildContext context, RequestMoneyState state, MoneyRequest request) {
    final colors = context.colors;
    final ownPhone = state.ownPhone;
    final amount = LkrFormat.withSymbol(request.amount, context.tr(LocaleKeys.currencySymbol));
    return [
      const SizedBox(height: AppSpacing.xxl),
      const Center(child: SuccessMark()),
      const SizedBox(height: AppSpacing.xl),
      Text(context.tr(LocaleKeys.requestSentTitle), style: AppTextStyles.headline, textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.xs),
      Text(
        context.tr(LocaleKeys.requestSentBody, args: [amount, request.counterparty.displayName]),
        style: AppTextStyles.body.copyWith(color: colors.textSecondary),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xxl),
      if (ownPhone != null) ...[
        AppButton(
          label: context.tr(LocaleKeys.requestShareLink),
          onPressed: () => unawaited(
            shareContent(
              context,
              text: context.tr(
                LocaleKeys.requestShareText,
                args: [
                  amount,
                  PaymentLink.build(amount: request.amount, note: request.note, phone: ownPhone),
                ],
              ),
            ),
          ),
          variant: AppButtonVariant.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      AppButton(label: context.tr(LocaleKeys.resultDone), onPressed: () => context.pop()),
    ];
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<RequestMoneyCubit, RequestMoneyState>(
    builder: (context, state) {
      final created = state.created;
      final payee = state.payee;
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            physics: const BouncingScrollPhysics(),
            children: [
              PageHeader(title: context.tr(LocaleKeys.requestTitle)),
              const SizedBox(height: AppSpacing.xl),
              AnimatedSwitcher(
                duration: AppMotion.base,
                child: Column(
                  key: ValueKey((created != null, payee != null)),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: created != null
                      ? _sent(context, state, created)
                      : payee != null
                      ? _enterAmount(context, state, payee)
                      : _choosePerson(context, state),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
