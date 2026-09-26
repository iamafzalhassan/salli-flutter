import '../../../../core/utils/money.dart';
import '../../domain/entities/category_spend.dart';
import '../../domain/entities/monthly_insights.dart';

class MonthlyInsightsModel {
  final int incomeCents;
  final int previousSpendingCents;
  final int spendingCents;

  final String month;

  final List<({int amountCents, String category, int count})> categories;

  const MonthlyInsightsModel({required this.incomeCents, required this.previousSpendingCents, required this.spendingCents, required this.month, required this.categories});

  factory MonthlyInsightsModel.fromJson(Map<String, dynamic> json) => MonthlyInsightsModel(
    incomeCents: json['incomeCents'] as int,
    previousSpendingCents: json['previousSpendingCents'] as int,
    spendingCents: json['spendingCents'] as int,
    month: json['month'] as String,
    categories: [for (final category in (json['categories'] as List<dynamic>).cast<Map<String, dynamic>>()) (amountCents: category['amountCents'] as int, category: category['category'] as String, count: category['count'] as int)],
  );

  MonthlyInsights toEntity() => MonthlyInsights(
    categories: [for (final category in categories) CategorySpend(amount: Money(category.amountCents), category: category.category, count: category.count)],
    income: Money(incomeCents),
    month: DateTime.parse('$month-01'),
    previousSpending: Money(previousSpendingCents),
    spending: Money(spendingCents),
  );
}
