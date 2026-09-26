import '../../../../core/errors/result.dart';
import '../entities/rewards_summary.dart';
import '../repositories/rewards_repository.dart';

class GetRewards {
  final RewardsRepository _repository;

  const GetRewards(this._repository);

  Future<Result<RewardsSummary>> call() => _repository.getRewards();
}
