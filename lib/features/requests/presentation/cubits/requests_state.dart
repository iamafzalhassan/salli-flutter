import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../payments/domain/entities/payment_draft.dart';
import '../../domain/entities/bill_split.dart';
import '../../domain/entities/money_request.dart';
import '../../domain/entities/request_direction.dart';
import '../../domain/entities/requests_tab.dart';

enum RequestsStatus { failure, loading, ready }

class RequestsState extends Equatable {
  final bool isBusy;

  final List<BillSplit> splits;

  final List<MoneyRequest> requests;

  final Failure? actionFailure;
  final Failure? failure;

  final PaymentDraft? draft;

  final RequestsStatus status;

  final RequestsTab tab;

  const RequestsState({this.isBusy = false, this.splits = const [], this.requests = const [], this.actionFailure, this.failure, this.draft, this.status = RequestsStatus.loading, this.tab = RequestsTab.incoming});

  List<MoneyRequest> get incoming => _inDirection(RequestDirection.incoming);
  List<MoneyRequest> get outgoing => _inDirection(RequestDirection.outgoing);

  RequestsState copyWith({bool? isBusy, List<BillSplit>? splits, List<MoneyRequest>? requests, Failure? Function()? actionFailure, Failure? Function()? failure, PaymentDraft? Function()? draft, RequestsStatus? status, RequestsTab? tab}) =>
      RequestsState(
        isBusy: isBusy ?? this.isBusy,
        splits: splits ?? this.splits,
        requests: requests ?? this.requests,
        actionFailure: actionFailure == null ? this.actionFailure : actionFailure(),
        failure: failure == null ? this.failure : failure(),
        draft: draft == null ? this.draft : draft(),
        status: status ?? this.status,
        tab: tab ?? this.tab,
      );

  List<MoneyRequest> _inDirection(RequestDirection direction) => [
    for (final request in requests)
      if (request.direction == direction) request,
  ];

  @override
  List<Object?> get props => [isBusy, splits, requests, actionFailure, failure, draft, status, tab];
}
