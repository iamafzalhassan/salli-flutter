import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

class CategorySpend extends Equatable {
  final int count;

  final String category;

  final Money amount;

  const CategorySpend({required this.count, required this.category, required this.amount});

  @override
  List<Object?> get props => [count, category, amount];
}
