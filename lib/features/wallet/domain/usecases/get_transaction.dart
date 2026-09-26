import '../../../../core/errors/result.dart';
import '../entities/transaction_detail.dart';
import '../repositories/wallet_repository.dart';

class GetTransaction {
  final WalletRepository _repository;

  const GetTransaction(this._repository);

  Future<Result<TransactionDetail>> call(String id) => _repository.getTransaction(id);
}
