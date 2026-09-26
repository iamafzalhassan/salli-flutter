import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/security/pin_policy.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_keypad.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/pin_dots.dart';
import '../../../../core/widgets/shake.dart';
import '../../../../core/widgets/upper_case_formatter.dart';
import '../cubits/pin_cubit.dart';
import '../cubits/pin_state.dart';
import '../widgets/auth_layout.dart';

class PinPage extends StatelessWidget {
  const PinPage({super.key});

  static const int _nicLength = 12;

  static (String, String) _copyKeys(PinState state) => switch (state.step) {
    PinStep.confirm => (LocaleKeys.authPinConfirmTitle, LocaleKeys.authPinConfirmBody),
    PinStep.create when state.isResetting => (LocaleKeys.authPinResetTitle, LocaleKeys.authPinResetBody),
    PinStep.create => (LocaleKeys.authPinCreateTitle, LocaleKeys.authPinCreateBody),
    PinStep.enter => (LocaleKeys.authPinEnterTitle, LocaleKeys.authPinEnterBody),
    PinStep.nic => (LocaleKeys.authPinNicTitle, LocaleKeys.authPinNicBody),
  };

  @override
  Widget build(BuildContext context) => BlocBuilder<PinCubit, PinState>(
    builder: (context, state) {
      final cubit = context.read<PinCubit>();
      final (titleKey, subtitleKey) = _copyKeys(state);
      final isNicStep = state.step == PinStep.nic;
      return AuthLayout(
        canGoBack: !state.isSubmitting,
        footer: isNicStep
            ? AppButton(label: context.tr(LocaleKeys.commonContinue), onPressed: cubit.submitNic)
            : Column(
                children: [
                  AppKeypad(onBackspace: cubit.backspace, onDigit: cubit.digitEntered),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(isLoading: state.isSubmitting, label: context.tr(LocaleKeys.commonConfirm), onPressed: state.pin.length == PinPolicy.length ? () => unawaited(cubit.confirm()) : null),
                ],
              ),
        subtitle: context.tr(subtitleKey),
        title: context.tr(titleKey),
        child: Column(
          children: [
            if (isNicStep)
              Shake(
                trigger: state.errorToken,
                child: AppTextField(
                  autofocus: true,
                  hint: context.tr(LocaleKeys.authPinNicHint),
                  icon: Icons.badge_rounded,
                  inputFormatters: const [UpperCaseFormatter()],
                  maxLength: _nicLength,
                  onChanged: cubit.nicChanged,
                  onSubmitted: (_) => cubit.submitNic(),
                ),
              )
            else
              Shake(
                trigger: state.errorToken,
                child: PinDots(filled: state.pin.length, hasError: state.failure != null && state.pin.isEmpty, length: PinPolicy.length),
              ),
            FailureText(failure: state.failure, textAlign: TextAlign.center),
            SizedBox(
              height: AppSpacing.touchTarget,
              child: Center(
                child: cubit.canReset ? AppTextButton(label: context.tr(LocaleKeys.authPinForgot), onPressed: cubit.startReset) : null,
              ),
            ),
          ],
        ),
      );
    },
  );
}
