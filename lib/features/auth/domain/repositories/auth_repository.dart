import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/security/session.dart';
import '../../../../core/utils/phone_number.dart';
import '../entities/otp_challenge.dart';
import '../entities/otp_verification.dart';

abstract interface class AuthRepository {
  Future<Result<Session>> createAccount(OtpVerification verification, String pin);

  Future<Result<OtpChallenge>> requestOtp(PhoneNumber phone);

  Future<Result<Session>> resetPin(OtpVerification verification, String pin, String? nic);

  Future<Result<Session>> signIn(OtpVerification verification, String pin);

  Future<void> signOut();

  Future<Result<void>> unlock(Authorization authorization);

  Future<Result<OtpVerification>> verifyOtp(OtpChallenge challenge, String code);
}
