import '../../../../core/errors/result.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_page.dart';
import '../repositories/wallet_repository.dart';

class GetTransactions {
  static const int pageSize = 20;

  final WalletRepository _repository;

  const GetTransactions(this._repository);

  Future<Result<TransactionPage>> call({String? cursor, int limit = pageSize, TransactionFilter filter = const TransactionFilter()}) => _repository.getTransactions(cursor: cursor, filter: filter, limit: limit);
}
