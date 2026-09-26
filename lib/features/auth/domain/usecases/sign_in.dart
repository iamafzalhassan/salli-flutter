import '../../../../core/errors/result.dart';
import '../../../../core/security/session.dart';
import '../entities/otp_verification.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository _repository;

  const SignIn(this._repository);

  Future<Result<Session>> call(OtpVerification verification, String pin) => _repository.signIn(verification, pin);
}
