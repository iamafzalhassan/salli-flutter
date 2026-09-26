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
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../banks/domain/entities/bank.dart';
import '../../../banks/domain/entities/bank_branch.dart';
import '../cubits/link_bank_cubit.dart';
import '../cubits/link_bank_state.dart';

class LinkBankPage extends StatelessWidget {
  const LinkBankPage({super.key});

  static const int _maxAccountLength = 16;

  static Future<void> _chooseBank(BuildContext context, List<Bank> banks) async {
    final cubit = context.read<LinkBankCubit>();
    final bank = await showAppSheet<Bank>(
      context,
      child: OptionSheet<Bank>(
        options: [for (final bank in banks) (leading: IconAvatar(icon: CategoryIcons.of('bank'), isAccent: false), subtitle: bank.shortName, title: bank.name, value: bank)],
        title: context.tr(LocaleKeys.bankChooseBank),
      ),
    );
    if (bank != null) await cubit.bankSelected(bank);
  }

  static Future<void> _chooseBranch(BuildContext context, List<BankBranch> branches) async {
    final cubit = context.read<LinkBankCubit>();
    final branch = await showAppSheet<BankBranch>(
      context,
      child: OptionSheet<BankBranch>(options: [for (final branch in branches) (leading: null, subtitle: branch.code, title: branch.name, value: branch)], title: context.tr(LocaleKeys.bankChooseBranch)),
    );
    if (branch != null) cubit.branchSelected(branch);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<LinkBankCubit, LinkBankState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<LinkBankCubit>();
      final bank = state.bank;
      final challenge = state.challenge;
      return Scaffold(
        body: SafeArea(
          child: FillScrollView(
            children: [
              PageHeader(title: context.tr(LocaleKeys.fundingLinkBank)),
              const SizedBox(height: AppSpacing.md),
              Text(context.tr(LocaleKeys.fundingLinkBankExplain), style: AppTextStyles.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              if (challenge == null) ...[
                SettingsRow(icon: Icons.account_balance_rounded, onPressed: () => unawaited(_chooseBank(context, state.banks)), title: bank?.name ?? context.tr(LocaleKeys.bankChooseBank), value: bank?.shortName),
                if (bank != null && bank.branchRequired) ...[
                  const SizedBox(height: AppSpacing.md),
                  SettingsRow(
                    icon: Icons.location_on_rounded,
                    onPressed: state.branches.isEmpty ? null : () => unawaited(_chooseBranch(context, state.branches)),
                    title: state.branch?.name ?? context.tr(LocaleKeys.bankChooseBranch),
                    value: state.branch?.code,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  hint: context.tr(LocaleKeys.bankAccountHint),
                  icon: Icons.tag_rounded,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  maxLength: _maxAccountLength,
                  onChanged: cubit.accountChanged,
                ),
              ] else ...[
                Text(context.tr(LocaleKeys.fundingCodeSent, args: [bank?.shortName ?? '']), style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  autofocus: true,
                  hint: context.tr(LocaleKeys.fundingCodeHint),
                  icon: Icons.sms_rounded,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  maxLength: challenge.codeLength,
                  onChanged: cubit.codeChanged,
                  onSubmitted: (_) => unawaited(cubit.verify()),
                ),
              ],
              FailureText(failure: state.failure),
              const Spacer(),
              if (challenge == null)
                AppButton(isLoading: state.isBusy, label: context.tr(LocaleKeys.fundingSendCode), onPressed: state.canSendCode ? () => unawaited(cubit.sendCode()) : null)
              else
                AppButton(isLoading: state.isBusy, label: context.tr(LocaleKeys.fundingVerify), onPressed: state.code.length == challenge.codeLength ? () => unawaited(cubit.verify()) : null),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => context.pop(),
    listenWhen: (previous, current) => current.isLinked && !previous.isLinked,
  );
}
