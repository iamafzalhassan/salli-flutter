import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'referral.dart';
import 'scratch_card.dart';

class RewardsSummary extends Equatable {
  final int minRedeemPoints;
  final int points;
  final int pointStep;

  final List<ScratchCard> scratchCards;

  final Money cashback;
  final Money pointValue;

  final Referral referral;

  const RewardsSummary({required this.minRedeemPoints, required this.points, required this.pointStep, required this.scratchCards, required this.cashback, required this.pointValue, required this.referral});

  int get redeemablePoints => points < minRedeemPoints ? 0 : points - points % pointStep;

  Money get pointsValue => Money(points * pointValue.cents);
  Money get redeemableValue => Money(redeemablePoints * pointValue.cents);

  @override
  List<Object?> get props => [minRedeemPoints, points, pointStep, scratchCards, cashback, pointValue, referral];
}
