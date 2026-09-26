import '../../../../core/errors/result.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetWallet {
  final WalletRepository _repository;

  const GetWallet(this._repository);

  Future<Result<Wallet>> call() => _repository.getWallet();
}
