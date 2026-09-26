import '../../../../core/errors/result.dart';
import '../../../../core/utils/phone_number.dart';
import '../entities/otp_challenge.dart';
import '../repositories/auth_repository.dart';

class RequestOtp {
  final AuthRepository _repository;

  const RequestOtp(this._repository);

  Future<Result<OtpChallenge>> call(PhoneNumber phone) => _repository.requestOtp(phone);
}
