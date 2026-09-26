import '../../../../core/errors/result.dart';
import '../entities/kyc_submission.dart';
import '../entities/verification.dart';
import '../repositories/account_repository.dart';

class SubmitKyc {
  final AccountRepository _repository;

  const SubmitKyc(this._repository);

  Future<Result<Verification>> call(KycSubmission submission) => _repository.submitKyc(submission);
}
