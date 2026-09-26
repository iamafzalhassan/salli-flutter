import '../../../../core/errors/result.dart';
import '../entities/card_transaction.dart';
import '../repositories/cards_repository.dart';

class GetCardTransactions {
  final CardsRepository _repository;

  const GetCardTransactions(this._repository);

  Future<Result<List<CardTransaction>>> call(String cardId) => _repository.getTransactions(cardId);
}
