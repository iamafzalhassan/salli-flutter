import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/utils/money.dart';
import '../entities/card_secrets.dart';
import '../entities/card_transaction.dart';
import '../entities/virtual_card.dart';

abstract interface class CardsRepository {
  Future<Result<VirtualCard>> getCard();

  Future<Result<List<CardTransaction>>> getTransactions(String cardId);

  Future<Result<CardTransaction>> makeTestPurchase(String cardId);

  Future<Result<CardSecrets>> reveal(String cardId, Authorization authorization);

  Future<Result<VirtualCard>> setFrozen(String cardId, {required bool isFrozen});

  Future<Result<VirtualCard>> setSpendLimit(String cardId, Money limit);
}
