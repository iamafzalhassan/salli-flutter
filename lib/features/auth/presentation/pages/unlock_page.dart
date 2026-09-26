import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/security/biometric_prompt_text.dart';
import '../../../../core/security/pin_policy.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_keypad.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../../../../core/widgets/biometric_key.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/pin_dots.dart';
import '../../../../core/widgets/shake.dart';
import '../cubits/unlock_cubit.dart';
import '../cubits/unlock_state.dart';
import '../widgets/auth_layout.dart';

class UnlockPage extends StatefulWidget {
  const UnlockPage({super.key});

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  bool _hasStarted = false;

  BiometricPromptText get _prompt => BiometricPromptText(cancel: context.tr(LocaleKeys.biometricUsePin), title: context.tr(LocaleKeys.biometricUnlock));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    unawaited(context.read<UnlockCubit>().start(_prompt));
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<UnlockCubit, UnlockState>(
    builder: (context, state) {
      final cubit = context.read<UnlockCubit>();
      return AuthLayout(
        canGoBack: false,
        footer: Column(
          children: [
            AppKeypad(leading: state.canUseBiometrics ? const BiometricKey() : null, onBackspace: cubit.backspace, onDigit: cubit.digitEntered, onLeading: state.canUseBiometrics ? () => unawaited(cubit.useBiometrics(_prompt)) : null),
            const SizedBox(height: AppSpacing.lg),
            AppButton(isLoading: state.isSubmitting, label: context.tr(LocaleKeys.commonConfirm), onPressed: state.pin.length == PinPolicy.length ? () => unawaited(cubit.confirm()) : null),
            const SizedBox(height: AppSpacing.sm),
            AppTextButton(label: context.tr(LocaleKeys.lockForgot), onPressed: state.isSubmitting ? null : cubit.signOut),
          ],
        ),
        subtitle: context.tr(LocaleKeys.lockBody),
        title: context.tr(LocaleKeys.lockTitle),
        child: Column(
          children: [
            Shake(
              trigger: state.errorToken,
              child: PinDots(filled: state.pin.length, hasError: state.failure != null && state.pin.isEmpty, length: PinPolicy.length),
            ),
            FailureText(failure: state.failure, textAlign: TextAlign.center),
          ],
        ),
      );
    },
  );
}
