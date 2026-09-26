import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

class CardTransaction extends Equatable {
  final String id;
  final String merchant;

  final DateTime createdAt;

  final Money amount;

  const CardTransaction({required this.id, required this.merchant, required this.createdAt, required this.amount});

  @override
  List<Object?> get props => [id, merchant, createdAt, amount];
}
