import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'recipient.dart';

class PaymentReceipt extends Equatable {
  final String id;
  final String reference;

  final String? note;

  final DateTime createdAt;

  final Money amount;
  final Money fee;

  final Recipient recipient;

  const PaymentReceipt({required this.id, required this.reference, this.note, required this.createdAt, required this.amount, required this.fee, required this.recipient});

  Money get total => amount + fee;

  @override
  List<Object?> get props => [id, reference, note, createdAt, amount, fee, recipient];
}
