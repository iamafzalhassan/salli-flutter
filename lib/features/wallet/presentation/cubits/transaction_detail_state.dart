import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/transaction_detail.dart';

enum TransactionDetailStatus { failure, loading, ready }

class TransactionDetailState extends Equatable {
  final bool isReporting;

  final Failure? failure;

  final TransactionDetail? detail;

  final TransactionDetailStatus status;

  const TransactionDetailState({this.isReporting = false, this.failure, this.detail, this.status = TransactionDetailStatus.loading});

  TransactionDetailState copyWith({bool? isReporting, Failure? Function()? failure, TransactionDetail? Function()? detail, TransactionDetailStatus? status}) =>
      TransactionDetailState(isReporting: isReporting ?? this.isReporting, failure: failure == null ? this.failure : failure(), detail: detail == null ? this.detail : detail(), status: status ?? this.status);

  @override
  List<Object?> get props => [isReporting, failure, detail, status];
}
