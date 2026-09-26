import '../../../../core/errors/result.dart';
import '../entities/account_limits.dart';
import '../entities/kyc_submission.dart';
import '../entities/verification.dart';

abstract interface class AccountRepository {
  Future<Result<AccountLimits>> getLimits();

  Future<Result<Verification>> getVerification();

  Future<Result<Verification>> submitKyc(KycSubmission submission);
}
