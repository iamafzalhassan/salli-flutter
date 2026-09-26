import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/widgets/app_refresh_view.dart';
import '../../../../core/widgets/app_share.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/text_entry_sheet.dart';
import '../../domain/entities/rewards_summary.dart';
import '../cubits/rewards_cubit.dart';
import '../cubits/rewards_state.dart';
import '../widgets/offer_tile.dart';
import '../widgets/referral_card.dart';
import '../widgets/rewards_skeleton.dart';
import '../widgets/rewards_summary_card.dart';
import '../widgets/scratch_card_tile.dart';
import '../widgets/scratch_sheet.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  static const double _cardAspectRatio = 1.1;

  static const int _columns = 2;
  static const int _maxCodeLength = 12;
  static const int _scratchedShown = 4;

  static List<Widget> _content(BuildContext context, RewardsState state, RewardsSummary summary) {
    final colors = context.colors;
    final referral = summary.referral;
    final cards = [...summary.scratchCards.where((card) => !card.isScratched), ...summary.scratchCards.where((card) => card.isScratched).take(_scratchedShown)];
    return [
      Entrance(
        child: RewardsSummaryCard(isRedeeming: state.isRedeeming, onRedeem: () => unawaited(_redeem(context, summary)), summary: summary),
      ),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: context.tr(LocaleKeys.rewardsScratchCards)),
      const SizedBox(height: AppSpacing.md),
      if (cards.isEmpty)
        Text(context.tr(LocaleKeys.rewardsNoCards), style: AppTextStyles.body.copyWith(color: colors.textSecondary))
      else
        GridView.count(
          childAspectRatio: _cardAspectRatio,
          crossAxisCount: _columns,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [for (final card in cards) ScratchCardTile(key: ValueKey(card.id), card: card, isBusy: state.scratchingId == card.id, onPressed: () => unawaited(_scratch(context, card.id)))],
        ),
      if (state.offers.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: context.tr(LocaleKeys.rewardsOffers)),
        const SizedBox(height: AppSpacing.sm),
        for (final offer in state.offers) OfferTile(key: ValueKey(offer.id), offer: offer),
      ],
      const SizedBox(height: AppSpacing.xl),
      ReferralCard(
        isClaiming: state.isClaiming,
        onClaim: () => unawaited(_claim(context)),
        onCopy: () {
          unawaited(Clipboard.setData(ClipboardData(text: referral.code)));
          showAppSnackBar(context, context.tr(LocaleKeys.rewardsCodeCopied));
        },
        onShare: () => unawaited(shareContent(context, text: context.tr(LocaleKeys.rewardsShareText, args: [referral.code, LkrFormat.withSymbol(referral.reward, context.tr(LocaleKeys.currencySymbol))]))),
        referral: referral,
      ),
    ];
  }

  static Future<void> _redeem(BuildContext context, RewardsSummary summary) async {
    final cubit = context.read<RewardsCubit>();
    final symbol = context.tr(LocaleKeys.currencySymbol);
    final value = LkrFormat.withSymbol(summary.redeemableValue, symbol);
    final isConfirmed = await showAppSheet<bool>(
      context,
      child: ConfirmSheet(
        body: context.tr(LocaleKeys.rewardsRedeemBody, args: ['${summary.redeemablePoints}', value]),
        confirmLabel: context.tr(LocaleKeys.rewardsRedeem),
        title: context.tr(LocaleKeys.rewardsRedeemTitle),
      ),
    );
    if (isConfirmed != true) return;
    final failure = await cubit.redeem();
    if (!context.mounted) return;
    showAppSnackBar(context, failure == null ? context.tr(LocaleKeys.rewardsRedeemed, args: [value]) : context.failureMessage(failure));
  }

  static Future<void> _scratch(BuildContext context, String cardId) async {
    final result = await context.read<RewardsCubit>().scratch(cardId);
    if (result == null || !context.mounted) return;
    switch (result) {
      case Ok(:final value):
        await HapticFeedback.selectionClick();
        if (context.mounted) await showAppSheet<void>(context, child: ScratchSheet(card: value));
      case Err(:final failure):
        showAppSnackBar(context, context.failureMessage(failure));
    }
  }

  static Future<void> _claim(BuildContext context) async {
    final cubit = context.read<RewardsCubit>();
    final code = await showAppSheet<String>(
      context,
      child: TextEntrySheet(confirmLabel: context.tr(LocaleKeys.rewardsClaimSubmit), hint: context.tr(LocaleKeys.rewardsClaimHint), maxLength: _maxCodeLength, title: context.tr(LocaleKeys.rewardsClaimTitle)),
    );
    if (code == null || code.isEmpty) return;
    final failure = await cubit.claimReferral(code);
    if (!context.mounted) return;
    final reward = cubit.state.summary?.referral.reward;
    showAppSnackBar(context, failure != null ? context.failureMessage(failure) : context.tr(LocaleKeys.rewardsClaimed, args: [if (reward != null) LkrFormat.withSymbol(reward, context.tr(LocaleKeys.currencySymbol))]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: BlocBuilder<RewardsCubit, RewardsState>(
        builder: (context, state) {
          final summary = state.summary;
          return AppRefreshView(
            onRefresh: context.read<RewardsCubit>().load,
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.lg, AppSpacing.screenPadding, AppSpacing.navClearance),
            children: [
              Text(context.tr(LocaleKeys.rewardsTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.xl),
              if (summary != null)
                ..._content(context, state, summary)
              else if (state.status == RewardsStatus.failure)
                StatusMessage(
                  actionLabel: context.tr(LocaleKeys.commonRetry),
                  body: context.failureMessage(state.failure!),
                  icon: Icons.cloud_off_rounded,
                  onAction: context.read<RewardsCubit>().load,
                  title: context.tr(LocaleKeys.commonErrorTitle),
                )
              else
                const RewardsSkeleton(cardAspectRatio: _cardAspectRatio, columns: _columns),
            ],
          );
        },
      ),
    ),
  );
}
