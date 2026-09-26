import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_keypad.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/decimal_key.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/shake.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_limits.dart';
import '../cubits/amount_cubit.dart';
import '../cubits/amount_state.dart';
import '../widgets/recipient_header.dart';

class AmountPage extends StatelessWidget {
  const AmountPage({super.key});

  static Future<void> _open(BuildContext context, PaymentDraft draft) async {
    final cubit = context.read<AmountCubit>();
    await context.push<void>(AppRoutes.payReview, extra: draft);
    if (!context.mounted) return;
    cubit.clearDraft();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AmountCubit, AmountState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<AmountCubit>();
      final symbol = context.tr(LocaleKeys.currencySymbol);
      final balance = state.balance;
      return Scaffold(
        body: SafeArea(
          child: FillScrollView(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const PageHeader(),
              RecipientHeader(recipient: cubit.recipient),
              const SizedBox(height: AppSpacing.xl),
              Shake(
                trigger: state.errorToken,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Text(
                      '$symbol ${state.input.display}',
                      key: ValueKey(state.input),
                      maxLines: 1,
                      style: AppTextStyles.balance.copyWith(color: state.input.isEmpty ? colors.textSecondary : colors.textPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedOpacity(
                duration: AppMotion.base,
                opacity: balance == null ? 0 : 1,
                child: Text(
                  context.tr(LocaleKeys.amountAvailable, args: [LkrFormat.withSymbol(balance ?? Money.zero, symbol)]),
                  maxLines: 1,
                  style: AppTextStyles.label.copyWith(color: colors.textSecondary),
                ),
              ),
              FailureText(failure: state.failure, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(hint: context.tr(LocaleKeys.amountNote), icon: Icons.edit_note_rounded, maxLength: PaymentLimits.maxNoteLength, onChanged: cubit.noteChanged),
              const Spacer(),
              const SizedBox(height: AppSpacing.lg),
              AppKeypad(leading: const DecimalKey(), onBackspace: cubit.backspace, onDigit: cubit.digitEntered, onLeading: cubit.decimalPoint),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: context.tr(LocaleKeys.amountReview), onPressed: state.input.money.isPositive ? cubit.review : null),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => unawaited(_open(context, state.draft!)),
    listenWhen: (previous, current) => current.draft != null && current.draft != previous.draft,
  );
}
