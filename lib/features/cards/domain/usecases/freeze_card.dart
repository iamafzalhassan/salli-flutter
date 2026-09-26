import '../../../../core/errors/result.dart';
import '../entities/virtual_card.dart';
import '../repositories/cards_repository.dart';

class FreezeCard {
  final CardsRepository _repository;

  const FreezeCard(this._repository);

  Future<Result<VirtualCard>> call(String cardId, {required bool isFrozen}) => _repository.setFrozen(cardId, isFrozen: isFrozen);
}
