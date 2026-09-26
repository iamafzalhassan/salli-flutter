import '../../../../core/errors/result.dart';
import '../entities/card_transaction.dart';
import '../repositories/cards_repository.dart';

class MakeTestPurchase {
  final CardsRepository _repository;

  const MakeTestPurchase(this._repository);

  Future<Result<CardTransaction>> call(String cardId) => _repository.makeTestPurchase(cardId);
}
