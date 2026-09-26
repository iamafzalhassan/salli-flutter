import 'dart:typed_data';

import '../../../../core/errors/result.dart';
import '../../../../core/events/app_event.dart';
import '../../../../core/events/app_events.dart';
import '../../../../core/network/api_guard.dart';
import '../../domain/entities/dispute.dart';
import '../../domain/entities/dispute_reason.dart';
import '../../domain/entities/monthly_insights.dart';
import '../../domain/entities/transaction_detail.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_page.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';
import '../statement/statement_document.dart';

class WalletRepositoryImpl implements WalletRepository {
  static const int _statementPageSize = 50;

  final AppEvents _events;

  final StatementDocument _statement;

  final WalletRemoteDataSource _remote;

  const WalletRepositoryImpl(this._events, this._statement, this._remote);

  Future<List<WalletTransaction>> _allTransactions(TransactionFilter filter) async {
    final items = <WalletTransaction>[];
    String? cursor;
    do {
      final page = (await _remote.getTransactions(cursor: cursor, filter: filter, limit: _statementPageSize)).toEntity();
      items.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return items.reversed.toList();
  }

  @override
  Stream<void> get changes => _events.stream.where((event) => event is WalletChanged);

  @override
  Future<Result<Uint8List>> exportStatement(DateTime from, DateTime to, {required String holder, required String phone}) => guardApi(
    () async => _statement.build(
      from: from,
      holder: holder,
      phone: phone,
      to: to,
      transactions: await _allTransactions(TransactionFilter(from: from, to: to)),
    ),
  );

  @override
  Future<Result<MonthlyInsights>> getInsights(DateTime month) => guardApi(() async => (await _remote.getInsights(month)).toEntity());

  @override
  Future<Result<TransactionDetail>> getTransaction(String id) => guardApi(() async => (await _remote.getTransaction(id)).toEntity());

  @override
  Future<Result<TransactionPage>> getTransactions({String? cursor, required int limit, TransactionFilter filter = const TransactionFilter()}) =>
      guardApi(() async => (await _remote.getTransactions(cursor: cursor, filter: filter, limit: limit)).toEntity());

  @override
  Future<Result<Wallet>> getWallet() => guardApi(() async => (await _remote.getWallet()).toEntity());

  @override
  Future<Result<Dispute>> reportProblem(String transactionId, DisputeReason reason, String? details) => guardApi(() async => (await _remote.reportProblem(transactionId, reason, details)).toEntity());
}
