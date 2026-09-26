import '../../../../core/errors/result.dart';
import '../entities/rewards_summary.dart';
import '../repositories/rewards_repository.dart';

class ClaimReferral {
  final RewardsRepository _repository;

  const ClaimReferral(this._repository);

  Future<Result<RewardsSummary>> call(String code) => _repository.claimReferral(code.trim().toUpperCase());
}
