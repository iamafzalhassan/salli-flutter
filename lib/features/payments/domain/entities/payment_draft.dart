import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'recipient.dart';

class PaymentDraft extends Equatable {
  final String idempotencyKey;

  final String? note;
  final String? requestId;

  final Money amount;

  final Recipient recipient;

  const PaymentDraft({required this.idempotencyKey, this.note, this.requestId, required this.amount, required this.recipient});

  @override
  List<Object?> get props => [idempotencyKey, note, requestId, amount, recipient];
}
