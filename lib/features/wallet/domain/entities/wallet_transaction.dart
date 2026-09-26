import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'transaction_status.dart';
import 'transaction_type.dart';

class WalletTransaction extends Equatable {
  final String counterpartyName;
  final String id;

  final DateTime createdAt;

  final Money amount;

  final TransactionStatus status;

  final TransactionType type;

  const WalletTransaction({required this.counterpartyName, required this.id, required this.createdAt, required this.amount, required this.status, required this.type});

  bool get isCredit => amount.isPositive;

  @override
  List<Object?> get props => [counterpartyName, id, createdAt, amount, status, type];
}
