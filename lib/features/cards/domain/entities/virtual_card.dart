import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'card_status.dart';

class VirtualCard extends Equatable {
  final int expiryMonth;
  final int expiryYear;

  final String holderName;
  final String id;
  final String last4;
  final String network;

  final CardStatus status;

  final Money spendLimit;
  final Money spent;

  const VirtualCard({required this.expiryMonth, required this.expiryYear, required this.holderName, required this.id, required this.last4, required this.network, required this.status, required this.spendLimit, required this.spent});

  bool get isFrozen => status == CardStatus.frozen;

  @override
  List<Object?> get props => [expiryMonth, expiryYear, holderName, id, last4, network, status, spendLimit, spent];
}
