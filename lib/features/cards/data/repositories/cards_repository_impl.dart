import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/security/approval_payload.dart';
import '../../../../core/security/approver.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/card_secrets.dart';
import '../../domain/entities/card_status.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/virtual_card.dart';
import '../../domain/repositories/cards_repository.dart';
import '../datasources/cards_remote_data_source.dart';

class CardsRepositoryImpl implements CardsRepository {
  final Approver _approver;

  final CardsRemoteDataSource _remote;

  const CardsRepositoryImpl(this._approver, this._remote);

  @override
  Future<Result<VirtualCard>> getCard() => guardApi(() async {
    final cards = await _remote.getCards();
    if (cards.isEmpty) throw const ApiException(failure: Failure(FailureCodes.notFound));
    return cards.first.toEntity();
  });

  @override
  Future<Result<List<CardTransaction>>> getTransactions(String cardId) => guardApi(() async => [for (final transaction in await _remote.getTransactions(cardId)) transaction.toEntity()]);

  @override
  Future<Result<CardTransaction>> makeTestPurchase(String cardId) => guardApi(() async => (await _remote.makeTestPurchase(cardId)).toEntity());

  @override
  Future<Result<CardSecrets>> reveal(String cardId, Authorization authorization) => guardApi(() async {
    final nonce = IdGenerator.next();
    final timestamp = '${DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond}';
    final approval = await _approver.approve(authorization, ApprovalPayload.cardReveal(cardId: cardId, nonce: nonce, timestamp: timestamp));
    return _remote.reveal(cardId, {...approval, 'nonce': nonce, 'timestamp': timestamp});
  });

  @override
  Future<Result<VirtualCard>> setFrozen(String cardId, {required bool isFrozen}) => guardApi(() async => (await _remote.update(cardId, {'status': (isFrozen ? CardStatus.frozen : CardStatus.active).name})).toEntity());

  @override
  Future<Result<VirtualCard>> setSpendLimit(String cardId, Money limit) => guardApi(() async => (await _remote.update(cardId, {'spendLimitCents': limit.cents})).toEntity());
}
