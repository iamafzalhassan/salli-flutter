import '../../../../core/errors/result.dart';
import '../../../../core/events/app_event.dart';
import '../../../../core/events/app_events.dart';
import '../../../../core/network/api_guard.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/rewards_summary.dart';
import '../../domain/entities/scratch_card.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../datasources/rewards_remote_data_source.dart';

class RewardsRepositoryImpl implements RewardsRepository {
  final AppEvents _events;

  final RewardsRemoteDataSource _remote;

  const RewardsRepositoryImpl(this._events, this._remote);

  RewardsSummary _walletChanged(RewardsSummary summary) {
    _events.publish(const WalletChanged());
    return summary;
  }

  @override
  Future<Result<RewardsSummary>> claimReferral(String code) => guardApi(() async => _walletChanged((await _remote.claimReferral(code)).toEntity()));

  @override
  Future<Result<List<Offer>>> getOffers() => guardApi(() async => [for (final offer in await _remote.getOffers()) offer.toEntity()]);

  @override
  Future<Result<RewardsSummary>> getRewards() => guardApi(() async => (await _remote.getRewards()).toEntity());

  @override
  Future<Result<RewardsSummary>> redeemPoints(int points, String idempotencyKey) => guardApi(() async => _walletChanged((await _remote.redeemPoints(points, idempotencyKey)).toEntity()));

  @override
  Future<Result<ScratchCard>> scratch(String cardId) => guardApi(() async {
    final card = (await _remote.scratch(cardId)).toEntity();
    if (card.isWin) _events.publish(const WalletChanged());
    return card;
  });
}
