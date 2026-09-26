import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/wallet_transaction.dart';

enum ActivityStatus { failure, loading, ready }

class ActivityState extends Equatable {
  final bool isExporting;
  final bool isLoadingMore;

  final int pendingRequests;

  final String? nextCursor;

  final List<WalletTransaction> items;

  final ActivityStatus status;

  final Failure? failure;

  final TransactionFilter filter;

  const ActivityState({this.isExporting = false, this.isLoadingMore = false, this.pendingRequests = 0, this.nextCursor, this.items = const [], this.status = ActivityStatus.loading, this.failure, this.filter = const TransactionFilter()});

  bool get hasMore => nextCursor != null;

  ActivityState copyWith({bool? isExporting, bool? isLoadingMore, int? pendingRequests, String? Function()? nextCursor, List<WalletTransaction>? items, ActivityStatus? status, Failure? Function()? failure, TransactionFilter? filter}) =>
      ActivityState(
        isExporting: isExporting ?? this.isExporting,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
        items: items ?? this.items,
        status: status ?? this.status,
        failure: failure == null ? this.failure : failure(),
        filter: filter ?? this.filter,
      );

  @override
  List<Object?> get props => [isExporting, isLoadingMore, pendingRequests, nextCursor, items, status, failure, filter];
}
