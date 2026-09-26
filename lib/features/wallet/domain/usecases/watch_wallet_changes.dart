import '../repositories/wallet_repository.dart';

class WatchWalletChanges {
  final WalletRepository _repository;

  const WatchWalletChanges(this._repository);

  Stream<void> call() => _repository.changes;
}
