import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_refresh_view.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/summary_row.dart';
import '../../../../core/widgets/usage_bar.dart';
import '../cubits/account_cubit.dart';
import '../cubits/account_state.dart';
import '../widgets/account_skeleton.dart';
import '../widgets/verification_card.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static List<Widget> _content(BuildContext context, AccountState state) {
    final profile = state.profile;
    final verification = state.verification;
    final limits = state.limits;
    if (state.status == AccountStatus.loading) return const [AccountSkeleton()];
    if (profile == null || verification == null || limits == null) {
      return [
        StatusMessage(
          actionLabel: context.tr(LocaleKeys.commonRetry),
          body: context.failureMessage(state.failure!),
          icon: Icons.cloud_off_rounded,
          onAction: context.read<AccountCubit>().load,
          title: context.tr(LocaleKeys.commonErrorTitle),
        ),
      ];
    }
    final symbol = context.tr(LocaleKeys.currencySymbol);
    final dateOfBirth = profile.dateOfBirth;
    final maskedNic = verification.maskedNic;
    return [
      Row(
        children: [
          Expanded(child: SectionHeader(title: context.tr(LocaleKeys.accountDetails))),
          AppIconButton(icon: Icons.edit_rounded, onPressed: () => unawaited(_openAndReload(context, AppRoutes.accountEdit)), semanticLabel: context.tr(LocaleKeys.accountEdit)),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Entrance(
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
          child: Column(
            children: [
              SummaryRow(label: context.tr(LocaleKeys.accountName), value: profile.displayName ?? context.tr(LocaleKeys.accountNotSet)),
              SummaryRow(label: context.tr(LocaleKeys.accountPhone), value: profile.phone.display),
              SummaryRow(label: context.tr(LocaleKeys.accountDateOfBirth), value: dateOfBirth == null ? context.tr(LocaleKeys.accountNotSet) : context.dateLabel(dateOfBirth)),
              if (maskedNic != null) SummaryRow(label: context.tr(LocaleKeys.accountNic), value: maskedNic),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.accountVerification)),
      const SizedBox(height: AppSpacing.sm),
      Entrance(
        index: 1,
        child: VerificationCard(onVerify: () => unawaited(_openAndReload(context, AppRoutes.kyc)), verification: verification),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.accountLimits, args: [context.tr('${LocaleKeys.kycTierPrefix}.${limits.tier.name}')])),
      const SizedBox(height: AppSpacing.sm),
      Entrance(
        index: 2,
        child: AppCard(
          child: Column(
            children: [
              SummaryRow(label: context.tr(LocaleKeys.accountPerPayment), value: LkrFormat.withSymbol(limits.perPayment, symbol)),
              const SizedBox(height: AppSpacing.md),
              UsageBar(label: context.tr(LocaleKeys.accountDaily), limit: limits.daily, used: limits.dailyUsed),
              const SizedBox(height: AppSpacing.lg),
              UsageBar(label: context.tr(LocaleKeys.accountMonthly), limit: limits.monthly, used: limits.monthlyUsed),
            ],
          ),
        ),
      ),
    ];
  }

  static Future<void> _openAndReload(BuildContext context, String route) async {
    final cubit = context.read<AccountCubit>();
    await context.push<void>(route);
    if (!context.mounted) return;
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountCubit, AccountState>(
    builder: (context, state) => Scaffold(
      body: SafeArea(
        child: AppRefreshView(
          onRefresh: context.read<AccountCubit>().load,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            PageHeader(title: context.tr(LocaleKeys.accountTitle)),
            const SizedBox(height: AppSpacing.xl),
            ..._content(context, state),
          ],
        ),
      ),
    ),
  );
}
