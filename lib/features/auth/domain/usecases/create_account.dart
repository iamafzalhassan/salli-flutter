import '../../../../core/errors/result.dart';
import '../../../../core/security/session.dart';
import '../entities/otp_verification.dart';
import '../repositories/auth_repository.dart';

class CreateAccount {
  final AuthRepository _repository;

  const CreateAccount(this._repository);

  Future<Result<Session>> call(OtpVerification verification, String pin) => _repository.createAccount(verification, pin);
}
