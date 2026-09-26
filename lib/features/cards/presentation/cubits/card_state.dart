import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/card_secrets.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/virtual_card.dart';

enum CardLoadStatus { failure, loading, ready }

class CardState extends Equatable {
  final bool canUseBiometrics;
  final bool isBusy;

  final List<CardTransaction> transactions;

  final CardLoadStatus status;

  final CardSecrets? secrets;

  final Failure? failure;

  final VirtualCard? card;

  const CardState({this.canUseBiometrics = false, this.isBusy = false, this.transactions = const [], this.status = CardLoadStatus.loading, this.secrets, this.failure, this.card});

  CardState copyWith({bool? canUseBiometrics, bool? isBusy, List<CardTransaction>? transactions, CardLoadStatus? status, CardSecrets? Function()? secrets, Failure? Function()? failure, VirtualCard? Function()? card}) => CardState(
    canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
    isBusy: isBusy ?? this.isBusy,
    transactions: transactions ?? this.transactions,
    status: status ?? this.status,
    secrets: secrets == null ? this.secrets : secrets(),
    failure: failure == null ? this.failure : failure(),
    card: card == null ? this.card : card(),
  );

  @override
  List<Object?> get props => [canUseBiometrics, isBusy, transactions, status, secrets, failure, card];
}
