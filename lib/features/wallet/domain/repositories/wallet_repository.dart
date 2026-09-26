import 'dart:typed_data';

import '../../../../core/errors/result.dart';
import '../entities/dispute.dart';
import '../entities/dispute_reason.dart';
import '../entities/monthly_insights.dart';
import '../entities/transaction_detail.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_page.dart';
import '../entities/wallet.dart';

abstract interface class WalletRepository {
  Stream<void> get changes;

  Future<Result<Uint8List>> exportStatement(DateTime from, DateTime to, {required String holder, required String phone});

  Future<Result<MonthlyInsights>> getInsights(DateTime month);

  Future<Result<TransactionDetail>> getTransaction(String id);

  Future<Result<TransactionPage>> getTransactions({String? cursor, required int limit, TransactionFilter filter = const TransactionFilter()});

  Future<Result<Wallet>> getWallet();

  Future<Result<Dispute>> reportProblem(String transactionId, DisputeReason reason, String? details);
}
