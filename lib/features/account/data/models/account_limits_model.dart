import '../../../../core/utils/money.dart';
import '../../domain/entities/account_limits.dart';
import '../../domain/entities/account_tier.dart';

class AccountLimitsModel {
  final int dailyCents;
  final int dailyUsedCents;
  final int monthlyCents;
  final int monthlyUsedCents;
  final int perPaymentCents;

  final String tier;

  const AccountLimitsModel({required this.dailyCents, required this.dailyUsedCents, required this.monthlyCents, required this.monthlyUsedCents, required this.perPaymentCents, required this.tier});

  factory AccountLimitsModel.fromJson(Map<String, dynamic> json) => AccountLimitsModel(
    dailyCents: json['dailyCents'] as int,
    dailyUsedCents: json['dailyUsedCents'] as int,
    monthlyCents: json['monthlyCents'] as int,
    monthlyUsedCents: json['monthlyUsedCents'] as int,
    perPaymentCents: json['perPaymentCents'] as int,
    tier: json['tier'] as String,
  );

  AccountLimits toEntity() => AccountLimits(
    daily: Money(dailyCents),
    dailyUsed: Money(dailyUsedCents),
    monthly: Money(monthlyCents),
    monthlyUsed: Money(monthlyUsedCents),
    perPayment: Money(perPaymentCents),
    tier: AccountTier.values.asNameMap()[tier] ?? AccountTier.basic,
  );
}
