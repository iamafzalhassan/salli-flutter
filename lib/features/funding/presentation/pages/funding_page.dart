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
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tile_skeleton.dart';
import '../../../payments/domain/entities/funding_source_type.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../cubits/funding_cubit.dart';
import '../cubits/funding_state.dart';

class FundingPage extends StatelessWidget {
  const FundingPage({super.key});

  static const int _skeletonRows = 2;

  static Future<void> _openAndReload(BuildContext context, String route) async {
    final cubit = context.read<FundingCubit>();
    await context.push<void>(route);
    if (!context.mounted) return;
    await cubit.load();
  }

  static Future<void> _open(BuildContext context, Recipient recipient) async {
    final cubit = context.read<FundingCubit>();
    await context.push<void>(AppRoutes.payAmount, extra: recipient);
    if (!context.mounted) return;
    cubit.clearResult();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<FundingCubit, FundingState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<FundingCubit>();
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            physics: const BouncingScrollPhysics(),
            children: [
              PageHeader(title: context.tr(state.isWithdrawal ? LocaleKeys.fundingWithdrawTitle : LocaleKeys.fundingAddTitle)),
              const SizedBox(height: AppSpacing.md),
              Text(context.tr(state.isWithdrawal ? LocaleKeys.fundingWithdrawBody : LocaleKeys.fundingAddBody), style: AppTextStyles.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: context.tr(LocaleKeys.fundingSources)),
              const SizedBox(height: AppSpacing.sm),
              ...switch (state.status) {
                FundingStatus.loading => [for (var index = 0; index < _skeletonRows; index++) const TileSkeleton(trailing: Skeleton.circle(size: AppSpacing.touchTarget))],
                FundingStatus.failure => [
                  StatusMessage(actionLabel: context.tr(LocaleKeys.commonRetry), body: context.failureMessage(state.failure!), icon: Icons.cloud_off_rounded, onAction: cubit.load, title: context.tr(LocaleKeys.commonErrorTitle)),
                ],
                FundingStatus.ready when state.sources.isEmpty => [Text(context.tr(LocaleKeys.fundingNoSources), style: AppTextStyles.body.copyWith(color: colors.textSecondary))],
                FundingStatus.ready => [
                  for (final (index, source) in state.sources.indexed)
                    Entrance(
                      index: index,
                      child: AppListTile(
                        leading: IconAvatar(icon: source.type == FundingSourceType.card ? Icons.credit_card_rounded : Icons.account_balance_rounded, isAccent: false),
                        onPressed: state.isBusy ? null : () => cubit.choose(source),
                        subtitle: context.tr('${LocaleKeys.fundingTypePrefix}.${source.type.name}'),
                        title: '${source.label} ••${source.last4}',
                        trailing: AppIconButton(icon: Icons.delete_outline_rounded, onPressed: state.isBusy ? null : () => unawaited(cubit.remove(source)), semanticLabel: context.tr(LocaleKeys.fundingRemove)),
                      ),
                    ),
                ],
              },
              FailureText(failure: state.status == FundingStatus.ready ? state.failure : null),
              const SizedBox(height: AppSpacing.xl),
              AppListTile(
                leading: const IconAvatar(icon: Icons.add_link_rounded),
                onPressed: () => unawaited(_openAndReload(context, AppRoutes.linkBank)),
                subtitle: context.tr(LocaleKeys.fundingLinkBankBody),
                title: context.tr(LocaleKeys.fundingLinkBank),
              ),
              if (!state.isWithdrawal)
                AppListTile(
                  leading: const IconAvatar(icon: Icons.add_card_rounded),
                  onPressed: () => unawaited(_openAndReload(context, AppRoutes.addCard)),
                  subtitle: context.tr(LocaleKeys.fundingAddCardBody),
                  title: context.tr(LocaleKeys.fundingAddCard),
                ),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => unawaited(_open(context, state.recipient!)),
    listenWhen: (previous, current) => current.recipient != null && previous.recipient == null,
  );
}
