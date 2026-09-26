import '../../../../core/errors/result.dart';
import '../entities/otp_challenge.dart';
import '../entities/otp_verification.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp {
  final AuthRepository _repository;

  const VerifyOtp(this._repository);

  Future<Result<OtpVerification>> call(OtpChallenge challenge, String code) => _repository.verifyOtp(challenge, code);
}
