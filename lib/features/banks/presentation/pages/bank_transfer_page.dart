import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tile_skeleton.dart';
import '../../domain/entities/bank_payee.dart';
import '../cubits/bank_payees_cubit.dart';
import '../cubits/bank_payees_state.dart';

class BankTransferPage extends StatelessWidget {
  const BankTransferPage({super.key});

  static const int _skeletonRows = 3;

  static const String _separator = ' · ';

  static List<Widget> _payees(BuildContext context, BankPayeesState state) {
    final cubit = context.read<BankPayeesCubit>();
    return switch (state.status) {
      BankPayeesStatus.loading => [for (var index = 0; index < _skeletonRows; index++) const TileSkeleton(trailing: Skeleton.circle(size: AppSpacing.touchTarget))],
      BankPayeesStatus.failure => [
        StatusMessage(actionLabel: context.tr(LocaleKeys.commonRetry), body: context.failureMessage(state.failure!), icon: Icons.cloud_off_rounded, onAction: cubit.load, title: context.tr(LocaleKeys.commonErrorTitle)),
      ],
      BankPayeesStatus.ready when state.payees.isEmpty => [Text(context.tr(LocaleKeys.bankNoPayees), style: AppTextStyles.body.copyWith(color: context.colors.textSecondary))],
      BankPayeesStatus.ready => [
        for (final (index, payee) in state.payees.indexed)
          Entrance(
            index: index,
            child: AppListTile(
              leading: IconAvatar(icon: CategoryIcons.of('bank'), isAccent: false),
              onPressed: () => unawaited(context.push<void>(AppRoutes.payAmount, extra: payee.account.recipient)),
              subtitle: [payee.bank.shortName, payee.account.accountNumber].join(_separator),
              title: payee.displayName,
              trailing: AppIconButton(icon: Icons.delete_outline_rounded, onPressed: () => unawaited(_confirmDelete(context, payee)), semanticLabel: context.tr(LocaleKeys.bankRemove)),
            ),
          ),
      ],
    };
  }

  static Future<void> _confirmDelete(BuildContext context, BankPayee payee) async {
    final cubit = context.read<BankPayeesCubit>();
    final confirmed = await showAppSheet<bool>(
      context,
      child: ConfirmSheet(
        body: context.tr(LocaleKeys.bankRemoveBody),
        confirmLabel: context.tr(LocaleKeys.bankRemove),
        isDanger: true,
        title: context.tr(LocaleKeys.bankRemoveTitle, args: [payee.displayName]),
      ),
    );
    if (confirmed ?? false) await cubit.delete(payee);
  }

  static Future<void> _addAccount(BuildContext context) async {
    final cubit = context.read<BankPayeesCubit>();
    await context.push<void>(AppRoutes.bankAccountNew);
    if (!context.mounted) return;
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<BankPayeesCubit, BankPayeesState>(
    builder: (context, state) => Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          physics: const BouncingScrollPhysics(),
          children: [
            PageHeader(title: context.tr(LocaleKeys.bankTitle)),
            const SizedBox(height: AppSpacing.xl),
            AppListTile(
              leading: const IconAvatar(icon: Icons.add_rounded),
              onPressed: () => unawaited(_addAccount(context)),
              subtitle: context.tr(LocaleKeys.bankNewBody),
              title: context.tr(LocaleKeys.bankNewTitle),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: context.tr(LocaleKeys.bankSaved)),
            const SizedBox(height: AppSpacing.sm),
            ..._payees(context, state),
            FailureText(failure: state.actionFailure),
          ],
        ),
      ),
    ),
  );
}
