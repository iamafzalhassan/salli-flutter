import '../../../../core/errors/result.dart';
import '../entities/offer.dart';
import '../repositories/rewards_repository.dart';

class GetOffers {
  final RewardsRepository _repository;

  const GetOffers(this._repository);

  Future<Result<List<Offer>>> call() => _repository.getOffers();
}
