import '../../../../core/utils/money.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/rewards_summary.dart';
import 'scratch_card_model.dart';

class RewardsSummaryModel {
  final bool canClaim;

  final int cashbackCents;
  final int joinedCount;
  final int minRedeemPoints;
  final int points;
  final int pointStep;
  final int pointValueCents;
  final int rewardCents;

  final String code;

  final List<ScratchCardModel> scratchCards;

  const RewardsSummaryModel({
    required this.canClaim,
    required this.cashbackCents,
    required this.joinedCount,
    required this.minRedeemPoints,
    required this.points,
    required this.pointStep,
    required this.pointValueCents,
    required this.rewardCents,
    required this.code,
    required this.scratchCards,
  });

  factory RewardsSummaryModel.fromJson(Map<String, dynamic> json) {
    final referral = json['referral'] as Map<String, dynamic>;
    return RewardsSummaryModel(
      canClaim: referral['canClaim'] as bool,
      cashbackCents: json['cashbackCents'] as int,
      joinedCount: referral['joinedCount'] as int,
      minRedeemPoints: json['minRedeemPoints'] as int,
      points: json['points'] as int,
      pointStep: json['pointStep'] as int,
      pointValueCents: json['pointValueCents'] as int,
      rewardCents: referral['rewardCents'] as int,
      code: referral['code'] as String,
      scratchCards: [for (final card in json['scratchCards'] as List<dynamic>) ScratchCardModel.fromJson(card as Map<String, dynamic>)],
    );
  }

  RewardsSummary toEntity() => RewardsSummary(
    cashback: Money(cashbackCents),
    minRedeemPoints: minRedeemPoints,
    points: points,
    pointStep: pointStep,
    pointValue: Money(pointValueCents),
    referral: Referral(canClaim: canClaim, code: code, joinedCount: joinedCount, reward: Money(rewardCents)),
    scratchCards: [for (final card in scratchCards) card.toEntity()],
  );
}
