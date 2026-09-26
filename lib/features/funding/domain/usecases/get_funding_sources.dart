import '../../../../core/errors/result.dart';
import '../entities/funding_source.dart';
import '../repositories/funding_repository.dart';

class GetFundingSources {
  final FundingRepository _repository;

  const GetFundingSources(this._repository);

  Future<Result<List<FundingSource>>> call() => _repository.getSources();
}
