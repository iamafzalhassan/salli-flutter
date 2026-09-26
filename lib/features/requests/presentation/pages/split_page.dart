import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../../core/widgets/amount_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/settings_toggle.dart';
import '../../../payments/domain/entities/payment_limits.dart';
import '../../domain/entities/requests_tab.dart';
import '../cubits/split_cubit.dart';
import '../cubits/split_state.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key});

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _chooseTotal(Money? current) async {
    final cubit = context.read<SplitCubit>();
    final total = await showAppSheet<Money>(
      context,
      child: AmountSheet(confirmLabel: context.tr(LocaleKeys.commonContinue), initial: current, limit: PaymentLimits.perPayment, title: context.tr(LocaleKeys.splitTotal)),
    );
    if (total != null && mounted) cubit.totalChanged(total);
  }

  Future<void> _addPhone() async {
    await context.read<SplitCubit>().addPhone();
    if (mounted && context.read<SplitCubit>().state.phone == null) _phoneController.clear();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<SplitCubit, SplitState>(
    builder: (context, state) {
      final cubit = context.read<SplitCubit>();
      final symbol = context.tr(LocaleKeys.currencySymbol);
      final total = state.total;
      final shares = state.shares;
      final people = {...state.recents, ...state.participants}.toList();
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            physics: const BouncingScrollPhysics(),
            children: [
              PageHeader(title: context.tr(LocaleKeys.splitTitle)),
              const SizedBox(height: AppSpacing.xl),
              SettingsRow(icon: Icons.payments_rounded, onPressed: () => unawaited(_chooseTotal(total)), title: context.tr(LocaleKeys.splitTotal), value: total == null ? null : LkrFormat.withSymbol(total, symbol)),
              const SizedBox(height: AppSpacing.md),
              AppTextField(hint: context.tr(LocaleKeys.splitNoteHint), icon: Icons.edit_note_rounded, maxLength: PaymentLimits.maxNoteLength, onChanged: cubit.noteChanged),
              const SizedBox(height: AppSpacing.md),
              SettingsToggle(icon: Icons.person_rounded, onChanged: cubit.includeSelfToggled, subtitle: context.tr(LocaleKeys.splitIncludeMeBody), title: context.tr(LocaleKeys.splitIncludeMe), value: state.includeSelf),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: context.tr(LocaleKeys.splitWith)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _phoneController,
                      hint: context.tr(LocaleKeys.sendPhoneHint),
                      icon: Icons.phone_iphone_rounded,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.phone,
                      maxLength: PhoneNumber.maxInputDigits,
                      onChanged: cubit.phoneChanged,
                      onSubmitted: (_) => unawaited(_addPhone()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppIconButton(icon: Icons.person_add_rounded, onPressed: state.phone == null || state.isLookingUp ? null : () => unawaited(_addPhone()), semanticLabel: context.tr(LocaleKeys.splitAddPerson)),
                ],
              ),
              FailureText(failure: state.failure),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                runSpacing: AppSpacing.sm,
                spacing: AppSpacing.sm,
                children: [
                  for (final payee in people) AppChip(icon: state.participants.contains(payee) ? Icons.check_rounded : null, isSelected: state.participants.contains(payee), label: payee.displayName, onPressed: () => cubit.toggle(payee)),
                ],
              ),
              if (shares.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    children: [
                      for (final (index, share) in shares.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  state.includeSelf && index == 0 ? context.tr(LocaleKeys.splitYou) : state.participants[index - (state.includeSelf ? 1 : 0)].displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.label,
                                ),
                              ),
                              Text(LkrFormat.withSymbol(share, symbol), maxLines: 1, style: AppTextStyles.amount),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                isLoading: state.isSubmitting,
                label: context.tr(LocaleKeys.splitSend, args: ['${state.participants.length}']),
                onPressed: state.canSubmit ? () => unawaited(cubit.submit()) : null,
              ),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => context.pushReplacement(AppRoutes.requests, extra: RequestsTab.splits),
    listenWhen: (previous, current) => current.created != null && previous.created == null,
  );
}
