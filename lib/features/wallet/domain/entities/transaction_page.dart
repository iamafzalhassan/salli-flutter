import 'package:equatable/equatable.dart';

import 'wallet_transaction.dart';

class TransactionPage extends Equatable {
  final String? nextCursor;

  final List<WalletTransaction> items;

  const TransactionPage({this.nextCursor, required this.items});

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [nextCursor, items];
}
