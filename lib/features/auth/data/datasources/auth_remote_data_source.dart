import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/security/session.dart';
import '../../../../core/security/session_codec.dart';
import '../models/auth_request_model.dart';
import '../models/otp_challenge_model.dart';
import '../models/otp_verification_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  const AuthRemoteDataSource(this._client);

  Future<Session> login(AuthRequestModel request) async => SessionCodec.fromApi(await _client.post(ApiPaths.login, body: request.toJson()));

  Future<void> logout() => _client.post(ApiPaths.logout);

  Future<Session> register(AuthRequestModel request) async => SessionCodec.fromApi(await _client.post(ApiPaths.register, body: request.toJson()));

  Future<OtpChallengeModel> requestOtp(String phone) async => OtpChallengeModel.fromJson(await _client.post(ApiPaths.otp, body: {'phone': phone}));

  Future<Session> resetPin(AuthRequestModel request) async => SessionCodec.fromApi(await _client.post(ApiPaths.pinReset, body: request.toJson()));

  Future<void> unlock(Map<String, dynamic> approval) => _client.post(ApiPaths.unlock, body: {'approval': approval});

  Future<OtpVerificationModel> verifyOtp(String challengeId, String code) async => OtpVerificationModel.fromJson(await _client.post(ApiPaths.otpVerify, body: {'challengeId': challengeId, 'code': code}));
}
