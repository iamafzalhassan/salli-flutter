import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../payments/domain/entities/payment_draft.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../domain/entities/money_request.dart';
import '../../domain/entities/requests_tab.dart';
import '../../domain/usecases/cancel_request.dart';
import '../../domain/usecases/decline_request.dart';
import '../../domain/usecases/get_requests.dart';
import '../../domain/usecases/get_splits.dart';
import '../../domain/usecases/remind_request.dart';
import 'requests_state.dart';

class RequestsCubit extends Cubit<RequestsState> {
  final CancelRequest _cancelRequest;

  final DeclineRequest _declineRequest;

  final GetRequests _getRequests;

  final GetSplits _getSplits;

  final RemindRequest _remindRequest;

  RequestsCubit(this._cancelRequest, this._declineRequest, this._getRequests, this._getSplits, this._remindRequest, {RequestsTab tab = RequestsTab.incoming}) : super(RequestsState(tab: tab));

  Future<void> cancel(MoneyRequest request) => _act(() => _cancelRequest(request.id));

  void clearDraft() => emit(state.copyWith(draft: () => null));

  Future<void> decline(MoneyRequest request) => _act(() => _declineRequest(request.id));

  Future<void> load() async {
    if (state.requests.isEmpty) emit(state.copyWith(failure: () => null, status: RequestsStatus.loading));
    final (requests, splits) = await (_getRequests(), _getSplits()).wait;
    if (isClosed) return;
    switch ((requests, splits)) {
      case (Ok(value: final requests), Ok(value: final splits)):
        emit(state.copyWith(failure: () => null, requests: requests, splits: splits, status: RequestsStatus.ready));
      case _:
        final failure = [requests, splits].whereType<Err<Object?>>().first.failure;
        emit(state.copyWith(failure: () => failure, status: state.requests.isEmpty ? RequestsStatus.failure : RequestsStatus.ready));
    }
  }

  void pay(MoneyRequest request) {
    if (!request.isPending) return;
    emit(
      state.copyWith(
        draft: () => PaymentDraft(amount: request.amount, idempotencyKey: IdGenerator.next(), note: request.note, recipient: PersonRecipient(request.counterparty), requestId: request.id),
      ),
    );
  }

  Future<void> remind(MoneyRequest request) => _act(() => _remindRequest(request.id));

  void tabSelected(RequestsTab tab) => emit(state.copyWith(actionFailure: () => null, tab: tab));

  Future<void> _act(Future<Result<MoneyRequest>> Function() action) async {
    if (state.isBusy) return;
    emit(state.copyWith(actionFailure: () => null, isBusy: true));
    final result = await action();
    if (isClosed) return;
    final Failure? failure = result is Err<MoneyRequest> ? result.failure : null;
    emit(state.copyWith(actionFailure: () => failure, isBusy: false));
    await load();
  }
}
