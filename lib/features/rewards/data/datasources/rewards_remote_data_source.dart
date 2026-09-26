import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/utils/path_template.dart';
import '../models/offer_model.dart';
import '../models/rewards_summary_model.dart';
import '../models/scratch_card_model.dart';

class RewardsRemoteDataSource {
  final ApiClient _client;

  const RewardsRemoteDataSource(this._client);

  Future<RewardsSummaryModel> claimReferral(String code) async => RewardsSummaryModel.fromJson(await _client.post(ApiPaths.referralClaim, body: {'code': code}));

  Future<List<OfferModel>> getOffers() async => [for (final item in (await _client.get(ApiPaths.offers))['items'] as List<dynamic>) OfferModel.fromJson(item as Map<String, dynamic>)];

  Future<RewardsSummaryModel> getRewards() async => RewardsSummaryModel.fromJson(await _client.get(ApiPaths.rewards));

  Future<RewardsSummaryModel> redeemPoints(int points, String idempotencyKey) async => RewardsSummaryModel.fromJson(await _client.post(ApiPaths.redeemPoints, body: {'points': points}, idempotencyKey: idempotencyKey));

  Future<ScratchCardModel> scratch(String cardId) async => ScratchCardModel.fromJson(await _client.post(ApiPaths.scratchCard.withId(cardId)));
}
