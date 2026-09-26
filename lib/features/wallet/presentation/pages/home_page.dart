import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../cubits/home_cubit.dart';
import '../cubits/home_state.dart';
import '../widgets/balance_summary.dart';
import '../widgets/home_header.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/quick_actions.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/upcoming_bill_tile.dart';
import '../widgets/wallet_actions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static List<Widget> _content(BuildContext context, HomeState state) {
    final cubit = context.read<HomeCubit>();
    return switch ((state.status, state.profile, state.wallet)) {
      (HomeStatus.ready, final profile?, final wallet?) => [
        Entrance(
          child: HomeHeader(profile: profile, unreadCount: state.unreadNotifications),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Entrance(
          index: 1,
          child: BalanceSummary(isHidden: state.isBalanceHidden, onToggle: cubit.toggleBalance, wallet: wallet),
        ),
        const SizedBox(height: AppSpacing.md),
        const Entrance(index: 1, child: WalletActions()),
        const SizedBox(height: AppSpacing.xl),
        const Entrance(index: 2, child: QuickActions()),
        if (state.upcomingBills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          SectionHeader(actionLabel: context.tr(LocaleKeys.homeSeeAll), onAction: () => unawaited(context.push<void>(AppRoutes.bills)), title: context.tr(LocaleKeys.homeUpcomingBills)),
          const SizedBox(height: AppSpacing.sm),
          for (final schedule in state.upcomingBills) Entrance(index: 3, child: UpcomingBillTile(schedule: schedule)),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Entrance(
          index: 3,
          child: SectionHeader(actionLabel: context.tr(LocaleKeys.homeSeeAll), onAction: () => context.go(AppRoutes.activity), title: context.tr(LocaleKeys.homeRecent)),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.recent.isEmpty)
          StatusMessage(body: context.tr(LocaleKeys.activityEmptyBody), icon: Icons.receipt_long_rounded, title: context.tr(LocaleKeys.activityEmptyTitle))
        else
          for (final (index, transaction) in state.recent.indexed)
            Entrance(
              index: index + 4,
              child: TransactionTile(showsDay: true, transaction: transaction),
            ),
      ],
      (HomeStatus.failure, _, _) => [
        StatusMessage(actionLabel: context.tr(LocaleKeys.commonRetry), body: context.failureMessage(state.failure!), icon: Icons.cloud_off_rounded, onAction: cubit.load, title: context.tr(LocaleKeys.commonErrorTitle)),
      ],
      _ => const [HomeSkeleton()],
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: context.read<HomeCubit>().load),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: AppSpacing.navClearance, left: AppSpacing.screenPadding, right: AppSpacing.screenPadding, top: AppSpacing.lg),
              sliver: SliverList.list(children: _content(context, state)),
            ),
          ],
        ),
      ),
    ),
  );
}
