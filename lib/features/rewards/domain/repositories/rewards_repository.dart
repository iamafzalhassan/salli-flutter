import '../../../../core/errors/result.dart';
import '../entities/offer.dart';
import '../entities/rewards_summary.dart';
import '../entities/scratch_card.dart';

abstract interface class RewardsRepository {
  Future<Result<RewardsSummary>> claimReferral(String code);

  Future<Result<List<Offer>>> getOffers();

  Future<Result<RewardsSummary>> getRewards();

  Future<Result<RewardsSummary>> redeemPoints(int points, String idempotencyKey);

  Future<Result<ScratchCard>> scratch(String cardId);
}
