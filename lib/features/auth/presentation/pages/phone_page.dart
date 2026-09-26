import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/phone_field.dart';
import '../cubits/phone_cubit.dart';
import '../cubits/phone_state.dart';
import '../widgets/auth_layout.dart';

class PhonePage extends StatelessWidget {
  const PhonePage({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<PhoneCubit, PhoneState>(
    builder: (context, state) {
      final cubit = context.read<PhoneCubit>();
      return AuthLayout(
        canGoBack: false,
        footer: Column(
          children: [
            Text(
              context.tr(LocaleKeys.authTerms),
              style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(isLoading: state.isSubmitting, label: context.tr(LocaleKeys.commonContinue), onPressed: state.phone == null ? null : cubit.submit),
          ],
        ),
        subtitle: context.tr(LocaleKeys.authPhoneBody),
        title: context.tr(LocaleKeys.authPhoneTitle),
        child: Column(
          children: [
            PhoneField(carrier: state.phone?.carrier, isEnabled: !state.isSubmitting, onChanged: cubit.inputChanged, onSubmitted: cubit.submit),
            FailureText(failure: state.failure),
          ],
        ),
      );
    },
    listener: (context, state) => unawaited(context.push<void>(AppRoutes.otp, extra: state.challenge)),
    listenWhen: (previous, current) => current.challenge != null && current.challenge != previous.challenge,
  );
}
