import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'category_spend.dart';

class MonthlyInsights extends Equatable {
  final List<CategorySpend> categories;

  final DateTime month;

  final Money income;
  final Money previousSpending;
  final Money spending;

  const MonthlyInsights({required this.categories, required this.month, required this.income, required this.previousSpending, required this.spending});

  @override
  List<Object?> get props => [categories, month, income, previousSpending, spending];
}
