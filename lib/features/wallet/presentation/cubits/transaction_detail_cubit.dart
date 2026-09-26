import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/dispute_reason.dart';
import '../../domain/usecases/get_transaction.dart';
import '../../domain/usecases/report_problem.dart';
import 'transaction_detail_state.dart';

class TransactionDetailCubit extends Cubit<TransactionDetailState> {
  final String _id;

  final GetTransaction _getTransaction;

  final ReportProblem _reportProblem;

  TransactionDetailCubit(this._id, this._getTransaction, this._reportProblem) : super(const TransactionDetailState());

  Future<void> load() async {
    emit(state.copyWith(failure: () => null, status: TransactionDetailStatus.loading));
    final result = await _getTransaction(_id);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => TransactionDetailState(detail: value, status: TransactionDetailStatus.ready),
      Err(:final failure) => TransactionDetailState(failure: failure, status: TransactionDetailStatus.failure),
    });
  }

  Future<void> report(DisputeReason reason, String? details) async {
    final detail = state.detail;
    if (detail == null || detail.dispute != null || state.isReporting) return;
    emit(state.copyWith(failure: () => null, isReporting: true));
    final result = await _reportProblem(_id, reason, details);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(detail: () => detail.withDispute(value), isReporting: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isReporting: false),
    });
  }
}
