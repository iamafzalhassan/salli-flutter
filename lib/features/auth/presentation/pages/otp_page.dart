import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_keypad.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/otp_slots.dart';
import '../../../../core/widgets/shake.dart';
import '../cubits/otp_cubit.dart';
import '../cubits/otp_state.dart';
import '../widgets/auth_layout.dart';
import '../widgets/resend_countdown.dart';
import '../widgets/sms_code_listener.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<OtpCubit, OtpState>(
    builder: (context, state) {
      final cubit = context.read<OtpCubit>();
      return SmsCodeListener(
        key: ValueKey(state.challenge.id),
        codeLength: state.challenge.codeLength,
        onCode: (code) => unawaited(cubit.codeReceived(code)),
        child: AuthLayout(
          footer: Column(
            children: [
              AppKeypad(onBackspace: cubit.backspace, onDigit: cubit.digitEntered),
              const SizedBox(height: AppSpacing.lg),
              AppButton(isLoading: state.isVerifying, label: context.tr(LocaleKeys.commonConfirm), onPressed: state.code.length == state.challenge.codeLength && !state.isResending ? () => unawaited(cubit.confirm()) : null),
            ],
          ),
          subtitle: context.tr(LocaleKeys.authOtpBody, args: [state.challenge.phone.display]),
          title: context.tr(LocaleKeys.authOtpTitle),
          child: Column(
            children: [
              Shake(
                trigger: state.errorToken,
                child: OtpSlots(hasError: state.failure != null, length: state.challenge.codeLength, value: state.code),
              ),
              FailureText(failure: state.failure, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              ResendCountdown(isBusy: state.isResending, onResend: state.isVerifying ? null : cubit.resend, secondsLeft: state.secondsUntilResend),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => context.pushReplacement(AppRoutes.pin, extra: state.verification),
    listenWhen: (previous, current) => current.verification != null && current.verification != previous.verification,
  );
}
