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
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/settings_toggle.dart';
import '../../../../core/widgets/upper_case_formatter.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../domain/entities/bill_account_kind.dart';
import '../cubits/bill_account_cubit.dart';
import '../cubits/bill_account_state.dart';

class BillAccountPage extends StatelessWidget {
  const BillAccountPage({super.key});

  static const int _maxAccountLength = 16;
  static const int _maxNicknameLength = 30;

  static final RegExp _alphanumeric = RegExp('[A-Za-z0-9]');

  static Future<void> _open(BuildContext context, Recipient recipient) async {
    final cubit = context.read<BillAccountCubit>();
    await context.push<void>(AppRoutes.payAmount, extra: recipient);
    if (!context.mounted) return;
    cubit.clearResult();
  }

  static (TextInputType, List<TextInputFormatter>) _inputFor(BillAccountKind kind) => switch (kind) {
    BillAccountKind.policy || BillAccountKind.contract => (TextInputType.text, [const UpperCaseFormatter(), FilteringTextInputFormatter.allow(_alphanumeric)]),
    BillAccountKind.phone => (TextInputType.phone, [FilteringTextInputFormatter.digitsOnly]),
    BillAccountKind.account || BillAccountKind.subscriber => (TextInputType.number, [FilteringTextInputFormatter.digitsOnly]),
  };

  @override
  Widget build(BuildContext context) => BlocConsumer<BillAccountCubit, BillAccountState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<BillAccountCubit>();
      final draft = cubit.draft;
      final biller = draft.biller;
      final (keyboardType, formatters) = _inputFor(biller.accountKind);
      return Scaffold(
        body: SafeArea(
          child: FillScrollView(
            children: [
              const PageHeader(),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: IconAvatar(icon: CategoryIcons.of(biller.category.name), size: AppSpacing.iconHero),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(biller.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              Text(context.tr('${LocaleKeys.billAccountKindPrefix}.${biller.accountKind.name}'), maxLines: 1, style: AppTextStyles.label.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              if (draft.isSaved)
                Text(state.accountNumber, maxLines: 1, style: AppTextStyles.title.copyWith(fontFeatures: AppTextStyles.tabular))
              else
                AppTextField(
                  autofocus: true,
                  hint: biller.accountHint,
                  icon: Icons.tag_rounded,
                  inputFormatters: formatters,
                  keyboardType: keyboardType,
                  maxLength: _maxAccountLength,
                  onChanged: cubit.accountChanged,
                  onSubmitted: (_) => unawaited(cubit.submit()),
                ),
              FailureText(failure: state.failure),
              if (!draft.isSaved) ...[
                const SizedBox(height: AppSpacing.lg),
                SettingsToggle(icon: Icons.bookmark_add_rounded, onChanged: cubit.saveToggled, subtitle: context.tr(LocaleKeys.billsSaveBody), title: context.tr(LocaleKeys.billsSaveToggle), value: state.shouldSave),
                if (state.shouldSave) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(hint: context.tr(LocaleKeys.billsNicknameHint), icon: Icons.label_outline_rounded, maxLength: _maxNicknameLength, onChanged: cubit.nicknameChanged),
                ],
              ],
              const Spacer(),
              const SizedBox(height: AppSpacing.xl),
              AppButton(isLoading: state.isLooking, label: context.tr(draft.isSaved ? LocaleKeys.commonRetry : LocaleKeys.commonContinue), onPressed: cubit.canSubmit ? () => unawaited(cubit.submit()) : null),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => unawaited(_open(context, state.recipient!)),
    listenWhen: (previous, current) => current.recipient != null && previous.recipient == null,
  );
}
