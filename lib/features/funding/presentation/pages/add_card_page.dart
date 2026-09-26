import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/card_number.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubits/add_card_cubit.dart';
import '../cubits/add_card_state.dart';

class AddCardPage extends StatelessWidget {
  const AddCardPage({super.key});

  static const int _cvvLength = 4;
  static const int _expiryLength = 4;

  @override
  Widget build(BuildContext context) => BlocConsumer<AddCardCubit, AddCardState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<AddCardCubit>();
      return Scaffold(
        body: SafeArea(
          child: FillScrollView(
            children: [
              PageHeader(title: context.tr(LocaleKeys.fundingAddCard)),
              const SizedBox(height: AppSpacing.md),
              Text(context.tr(LocaleKeys.fundingCardExplain), style: AppTextStyles.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                hint: context.tr(LocaleKeys.fundingCardNumber),
                icon: Icons.credit_card_rounded,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                maxLength: CardNumber.maxDigits,
                onChanged: cubit.numberChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hint: context.tr(LocaleKeys.fundingCardExpiry),
                      icon: Icons.event_rounded,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      maxLength: _expiryLength,
                      onChanged: cubit.expiryChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      hint: context.tr(LocaleKeys.fundingCardCvv),
                      icon: Icons.password_rounded,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      maxLength: _cvvLength,
                      onChanged: cubit.cvvChanged,
                    ),
                  ),
                ],
              ),
              FailureText(failure: state.failure),
              const Spacer(),
              AppButton(isLoading: state.isSaving, label: context.tr(LocaleKeys.fundingAddCard), onPressed: () => unawaited(cubit.save())),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => context.pop(),
    listenWhen: (previous, current) => current.isAdded && !previous.isAdded,
  );
}
