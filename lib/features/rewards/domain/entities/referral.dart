import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

class Referral extends Equatable {
  final bool canClaim;

  final int joinedCount;

  final String code;

  final Money reward;

  const Referral({required this.canClaim, required this.joinedCount, required this.code, required this.reward});

  @override
  List<Object?> get props => [canClaim, joinedCount, code, reward];
}
