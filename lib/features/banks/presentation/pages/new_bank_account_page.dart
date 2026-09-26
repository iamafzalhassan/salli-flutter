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
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/option_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/settings_toggle.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/bank_branch.dart';
import '../cubits/new_bank_account_cubit.dart';
import '../cubits/new_bank_account_state.dart';

class NewBankAccountPage extends StatelessWidget {
  const NewBankAccountPage({super.key});

  static const int _maxAccountLength = 16;
  static const int _maxNicknameLength = 30;

  static Future<void> _chooseBank(BuildContext context, List<Bank> banks) async {
    final cubit = context.read<NewBankAccountCubit>();
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
    final cubit = context.read<NewBankAccountCubit>();
    final branch = await showAppSheet<BankBranch>(
      context,
      child: OptionSheet<BankBranch>(options: [for (final branch in branches) (leading: null, subtitle: branch.code, title: branch.name, value: branch)], title: context.tr(LocaleKeys.bankChooseBranch)),
    );
    if (branch != null) cubit.branchSelected(branch);
  }

  static Future<void> _open(BuildContext context, Recipient recipient) async {
    final cubit = context.read<NewBankAccountCubit>();
    await context.push<void>(AppRoutes.payAmount, extra: recipient);
    if (!context.mounted) return;
    cubit.clearResult();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<NewBankAccountCubit, NewBankAccountState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<NewBankAccountCubit>();
      final bank = state.bank;
      final account = state.account;
      return Scaffold(
        body: SafeArea(
          child: FillScrollView(
            children: [
              PageHeader(title: context.tr(LocaleKeys.bankNewTitle)),
              const SizedBox(height: AppSpacing.xl),
              SettingsRow(icon: Icons.account_balance_rounded, onPressed: state.isLoading ? null : () => unawaited(_chooseBank(context, state.banks)), title: bank?.name ?? context.tr(LocaleKeys.bankChooseBank), value: bank?.shortName),
              if (bank != null && bank.branchRequired) ...[
                const SizedBox(height: AppSpacing.md),
                SettingsRow(
                  icon: Icons.location_on_rounded,
                  onPressed: state.branches.isEmpty ? null : () => unawaited(_chooseBranch(context, state.branches)),
                  title: state.branch?.name ?? context.tr(LocaleKeys.bankChooseBranch),
                  value: state.branch?.code,
                ),
              ],
              if (bank != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  hint: context.tr(LocaleKeys.bankAccountHint),
                  icon: Icons.tag_rounded,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  maxLength: _maxAccountLength,
                  onChanged: cubit.accountChanged,
                  onSubmitted: (_) => unawaited(cubit.lookup()),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr(LocaleKeys.bankFeeNote, args: [LkrFormat.withSymbol(bank.fee, context.tr(LocaleKeys.currencySymbol))]),
                  style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                ),
              ],
              FailureText(failure: state.failure),
              AnimatedSize(
                alignment: Alignment.topCenter,
                curve: AppMotion.standard,
                duration: AppMotion.base,
                child: account == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppCard(
                              child: Row(
                                children: [
                                  Icon(Icons.verified_rounded, color: colors.accentInk, size: AppSpacing.iconMd),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(context.tr(LocaleKeys.bankAccountHolder), maxLines: 1, style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(account.accountName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SettingsToggle(icon: Icons.bookmark_add_rounded, onChanged: cubit.saveToggled, subtitle: context.tr(LocaleKeys.bankSaveBody), title: context.tr(LocaleKeys.bankSaveToggle), value: state.shouldSave),
                            if (state.shouldSave) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(hint: context.tr(LocaleKeys.bankNicknameHint), icon: Icons.label_outline_rounded, maxLength: _maxNicknameLength, onChanged: cubit.nicknameChanged),
                            ],
                          ],
                        ),
                      ),
              ),
              const Spacer(),
              const SizedBox(height: AppSpacing.xl),
              if (account == null)
                AppButton(isLoading: state.isLooking, label: context.tr(LocaleKeys.bankCheckAccount), onPressed: state.canLookup ? () => unawaited(cubit.lookup()) : null)
              else
                AppButton(isLoading: state.isLooking, label: context.tr(LocaleKeys.commonContinue), onPressed: () => unawaited(cubit.proceed())),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => unawaited(_open(context, state.recipient!)),
    listenWhen: (previous, current) => current.recipient != null && previous.recipient == null,
  );
}
