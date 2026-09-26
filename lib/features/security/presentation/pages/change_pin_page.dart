import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/security/pin_policy.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_keypad.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pin_dots.dart';
import '../../../../core/widgets/shake.dart';
import '../cubits/change_pin_cubit.dart';
import '../cubits/change_pin_state.dart';

class ChangePinPage extends StatelessWidget {
  const ChangePinPage({super.key});

  static (String, String) _copyKeys(ChangePinStep step) => switch (step) {
    ChangePinStep.confirm => (LocaleKeys.securityPinConfirmTitle, LocaleKeys.securityPinConfirmBody),
    ChangePinStep.create => (LocaleKeys.securityPinNewTitle, LocaleKeys.securityPinNewBody),
    ChangePinStep.current => (LocaleKeys.securityPinCurrentTitle, LocaleKeys.securityPinCurrentBody),
  };

  @override
  Widget build(BuildContext context) => BlocConsumer<ChangePinCubit, ChangePinState>(
    builder: (context, state) {
      final cubit = context.read<ChangePinCubit>();
      final (titleKey, bodyKey) = _copyKeys(state.step);
      return PopScope(
        canPop: !state.isSubmitting,
        child: Scaffold(
          body: SafeArea(
            child: FillScrollView(
              children: [
                const PageHeader(),
                const SizedBox(height: AppSpacing.xl),
                Text(context.tr(titleKey), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline),
                const SizedBox(height: AppSpacing.xs),
                Text(context.tr(bodyKey), style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
                const Spacer(),
                Shake(
                  trigger: state.errorToken,
                  child: PinDots(filled: state.pin.length, hasError: state.failure != null && state.pin.isEmpty, length: PinPolicy.length),
                ),
                FailureText(failure: state.failure, textAlign: TextAlign.center),
                const Spacer(),
                AppKeypad(onBackspace: cubit.backspace, onDigit: cubit.digitEntered),
                const SizedBox(height: AppSpacing.lg),
                AppButton(isLoading: state.isSubmitting, label: context.tr(LocaleKeys.commonConfirm), onPressed: state.pin.length == PinPolicy.length ? () => unawaited(cubit.confirm()) : null),
              ],
            ),
          ),
        ),
      );
    },
    listener: (context, state) {
      showAppSnackBar(context, context.tr(LocaleKeys.securityPinChanged));
      context.pop();
    },
    listenWhen: (previous, current) => !previous.isDone && current.isDone,
  );
}
