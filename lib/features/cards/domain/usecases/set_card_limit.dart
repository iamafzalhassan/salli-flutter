import '../../../../core/errors/result.dart';
import '../../../../core/utils/money.dart';
import '../entities/virtual_card.dart';
import '../repositories/cards_repository.dart';

class SetCardLimit {
  final CardsRepository _repository;

  const SetCardLimit(this._repository);

  Future<Result<VirtualCard>> call(String cardId, Money limit) => _repository.setSpendLimit(cardId, limit);
}
