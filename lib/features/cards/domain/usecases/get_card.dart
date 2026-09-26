import '../../../../core/errors/result.dart';
import '../entities/virtual_card.dart';
import '../repositories/cards_repository.dart';

class GetCard {
  final CardsRepository _repository;

  const GetCard(this._repository);

  Future<Result<VirtualCard>> call() => _repository.getCard();
}
