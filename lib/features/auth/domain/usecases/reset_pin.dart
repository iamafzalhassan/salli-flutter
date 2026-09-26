import '../../../../core/errors/result.dart';
import '../../../../core/security/session.dart';
import '../entities/otp_verification.dart';
import '../repositories/auth_repository.dart';

class ResetPin {
  final AuthRepository _repository;

  const ResetPin(this._repository);

  Future<Result<Session>> call(OtpVerification verification, String pin, String? nic) => _repository.resetPin(verification, pin, nic);
}
