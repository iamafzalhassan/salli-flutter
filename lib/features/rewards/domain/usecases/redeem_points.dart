import '../../../../core/errors/result.dart';
import '../entities/rewards_summary.dart';
import '../repositories/rewards_repository.dart';

class RedeemPoints {
  final RewardsRepository _repository;

  const RedeemPoints(this._repository);

  Future<Result<RewardsSummary>> call(int points, String idempotencyKey) => _repository.redeemPoints(points, idempotencyKey);
}
