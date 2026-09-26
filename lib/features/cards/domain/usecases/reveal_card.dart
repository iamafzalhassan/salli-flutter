import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../entities/card_secrets.dart';
import '../repositories/cards_repository.dart';

class RevealCard {
  final CardsRepository _repository;

  const RevealCard(this._repository);

  Future<Result<CardSecrets>> call(String cardId, Authorization authorization) => _repository.reveal(cardId, authorization);
}
