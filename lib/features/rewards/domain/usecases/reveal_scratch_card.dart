import '../../../../core/errors/result.dart';
import '../entities/scratch_card.dart';
import '../repositories/rewards_repository.dart';

class RevealScratchCard {
  final RewardsRepository _repository;

  const RevealScratchCard(this._repository);

  Future<Result<ScratchCard>> call(String cardId) => _repository.scratch(cardId);
}
