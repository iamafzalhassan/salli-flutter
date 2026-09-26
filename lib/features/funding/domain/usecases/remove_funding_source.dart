import '../../../../core/errors/result.dart';
import '../repositories/funding_repository.dart';

class RemoveFundingSource {
  final FundingRepository _repository;

  const RemoveFundingSource(this._repository);

  Future<Result<void>> call(String sourceId) => _repository.removeSource(sourceId);
}
