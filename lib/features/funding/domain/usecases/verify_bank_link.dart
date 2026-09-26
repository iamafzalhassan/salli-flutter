import '../../../../core/errors/result.dart';
import '../entities/funding_source.dart';
import '../repositories/funding_repository.dart';

class VerifyBankLink {
  final FundingRepository _repository;

  const VerifyBankLink(this._repository);

  Future<Result<FundingSource>> call(String challengeId, String code) => _repository.verifyBankLink(challengeId, code);
}
