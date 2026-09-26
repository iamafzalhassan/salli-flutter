import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/bank_payee.dart';

enum BankPayeesStatus { failure, loading, ready }

class BankPayeesState extends Equatable {
  final bool isBusy;

  final List<BankPayee> payees;

  final BankPayeesStatus status;

  final Failure? actionFailure;
  final Failure? failure;

  const BankPayeesState({this.isBusy = false, this.payees = const [], this.status = BankPayeesStatus.loading, this.actionFailure, this.failure});

  BankPayeesState copyWith({bool? isBusy, List<BankPayee>? payees, BankPayeesStatus? status, Failure? Function()? actionFailure, Failure? Function()? failure}) => BankPayeesState(
    isBusy: isBusy ?? this.isBusy,
    payees: payees ?? this.payees,
    status: status ?? this.status,
    actionFailure: actionFailure == null ? this.actionFailure : actionFailure(),
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [isBusy, payees, status, actionFailure, failure];
}
