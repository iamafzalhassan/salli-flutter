import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../payments/domain/entities/payee.dart';
import 'request_status.dart';

class SplitShare extends Equatable {
  final bool isSelf;

  final Money amount;

  final Payee? payee;

  final RequestStatus status;

  const SplitShare({required this.isSelf, required this.amount, this.payee, required this.status});

  @override
  List<Object?> get props => [isSelf, amount, payee, status];
}
