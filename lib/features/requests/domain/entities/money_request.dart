import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../payments/domain/entities/payee.dart';
import 'request_direction.dart';
import 'request_status.dart';

class MoneyRequest extends Equatable {
  final String id;

  final String? note;
  final String? splitId;

  final DateTime createdAt;

  final DateTime? remindedAt;

  final Money amount;

  final Payee counterparty;

  final RequestDirection direction;

  final RequestStatus status;

  const MoneyRequest({required this.id, this.note, this.splitId, required this.createdAt, this.remindedAt, required this.amount, required this.counterparty, required this.direction, required this.status});

  bool get isPending => status == RequestStatus.pending;

  @override
  List<Object?> get props => [id, note, splitId, createdAt, remindedAt, amount, counterparty, direction, status];
}
