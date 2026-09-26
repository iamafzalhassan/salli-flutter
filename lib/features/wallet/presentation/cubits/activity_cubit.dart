import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../requests/domain/entities/request_direction.dart';
import '../../../requests/domain/usecases/get_requests.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/usecases/export_statement.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/watch_wallet_changes.dart';
import 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  static const Duration searchDelay = Duration(milliseconds: 350);

  final ExportStatement _exportStatement;

  final GetRequests _getRequests;

  final GetTransactions _getTransactions;

  late final StreamSubscription<void> _walletChanges;

  Timer? _searchTimer;

  ActivityCubit(this._exportStatement, this._getRequests, this._getTransactions, WatchWalletChanges watchWalletChanges) : super(const ActivityState()) {
    _walletChanges = watchWalletChanges().listen((_) => unawaited(load()));
  }

  Future<void> load() async {
    final filter = state.filter;
    if (state.items.isEmpty) emit(state.copyWith(failure: () => null, status: ActivityStatus.loading));
    final (result, requests) = await (_getTransactions(filter: filter), _getRequests()).wait;
    if (isClosed || filter != state.filter) return;
    final pendingRequests = switch (requests) {
      Ok(:final value) => value.where((request) => request.isPending && request.direction == RequestDirection.incoming).length,
      Err() => state.pendingRequests,
    };
    emit(switch (result) {
      Ok(:final value) => state.copyWith(failure: () => null, isLoadingMore: false, items: value.items, nextCursor: () => value.nextCursor, pendingRequests: pendingRequests, status: ActivityStatus.ready),
      Err(:final failure) => state.copyWith(failure: () => failure, pendingRequests: pendingRequests, status: state.items.isEmpty ? ActivityStatus.failure : ActivityStatus.ready),
    });
  }

  Future<Result<Uint8List>> exportStatement(DateTime from, DateTime to) async {
    emit(state.copyWith(isExporting: true));
    final result = await _exportStatement(from, to);
    if (!isClosed) emit(state.copyWith(isExporting: false));
    return result;
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    final filter = state.filter;
    if (cursor == null || state.isLoadingMore || state.status != ActivityStatus.ready) return;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getTransactions(cursor: cursor, filter: filter);
    if (isClosed || filter != state.filter) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(isLoadingMore: false, items: [...state.items, ...value.items], nextCursor: () => value.nextCursor),
      Err(:final failure) => state.copyWith(failure: () => failure, isLoadingMore: false),
    });
  }

  void search(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () => unawaited(applyFilter(state.filter.copyWith(query: query))));
  }

  Future<void> applyFilter(TransactionFilter filter) async {
    if (filter == state.filter) return;
    emit(state.copyWith(failure: () => null, filter: filter, isLoadingMore: false, items: const [], nextCursor: () => null, status: ActivityStatus.loading));
    await load();
  }

  @override
  Future<void> close() async {
    _searchTimer?.cancel();
    await _walletChanges.cancel();
    return super.close();
  }
}
