import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'account_tier.dart';

class AccountLimits extends Equatable {
  final AccountTier tier;

  final Money daily;
  final Money dailyUsed;
  final Money monthly;
  final Money monthlyUsed;
  final Money perPayment;

  const AccountLimits({required this.tier, required this.daily, required this.dailyUsed, required this.monthly, required this.monthlyUsed, required this.perPayment});

  Money get dailyRemaining => _atLeastZero(daily - dailyUsed);
  Money get monthlyRemaining => _atLeastZero(monthly - monthlyUsed);

  Money _atLeastZero(Money money) => money.isNegative ? Money.zero : money;

  @override
  List<Object?> get props => [tier, daily, dailyUsed, monthly, monthlyUsed, perPayment];
}
