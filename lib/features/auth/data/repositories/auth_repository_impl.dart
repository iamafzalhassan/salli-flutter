import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/security/app_lock.dart';
import '../../../../core/security/approval_payload.dart';
import '../../../../core/security/approver.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/security/biometric_vault.dart';
import '../../../../core/security/device_identity.dart';
import '../../../../core/security/pin_credential.dart';
import '../../../../core/security/session.dart';
import '../../../../core/security/session_store.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/otp_verification.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppLock _appLock;

  final Approver _approver;

  final AuthRemoteDataSource _remote;

  final BiometricVault _biometricVault;

  final DeviceIdentity _deviceIdentity;

  final PinCredential _pinCredential;

  final SessionStore _sessionStore;

  const AuthRepositoryImpl(this._appLock, this._approver, this._remote, this._biometricVault, this._deviceIdentity, this._pinCredential, this._sessionStore);

  Future<Result<Session>> _authenticate(OtpVerification verification, String pin, Future<Session> Function(AuthRequestModel request) send, {String? nic}) => guardApi(() async {
    final device = await _deviceIdentity.prepare();
    await _pinCredential.remember(verification.pinSalt);
    final session = await send(AuthRequestModel(device: device, nic: nic, pinHash: await _pinCredential.hash(pin), registrationToken: verification.registrationToken));
    await _sessionStore.save(session);
    return session;
  });

  Future<void> _endSession() async {
    await _sessionStore.clear();
    await _pinCredential.clear();
    await _biometricVault.reset();
  }

  Future<void> _unlockRemotely(Authorization authorization) async {
    final nonce = IdGenerator.next();
    final timestamp = '${DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond}';
    final approval = await _approver.approve(authorization, ApprovalPayload.unlock(nonce: nonce, timestamp: timestamp));
    await _remote.unlock({...approval, 'nonce': nonce, 'timestamp': timestamp});
  }

  @override
  Future<Result<Session>> createAccount(OtpVerification verification, String pin) => _authenticate(verification, pin, _remote.register);

  @override
  Future<Result<OtpChallenge>> requestOtp(PhoneNumber phone) => guardApi(() async => (await _remote.requestOtp(phone.e164)).toEntity(phone));

  @override
  Future<Result<Session>> resetPin(OtpVerification verification, String pin, String? nic) => _authenticate(verification, pin, _remote.resetPin, nic: nic);

  @override
  Future<Result<Session>> signIn(OtpVerification verification, String pin) => _authenticate(verification, pin, _remote.login);

  @override
  Future<void> signOut() async {
    try {
      await _remote.logout();
    } on ApiException {
      return;
    } finally {
      await _endSession();
    }
  }

  @override
  Future<Result<void>> unlock(Authorization authorization) async {
    final result = await guardApi(() => _unlockRemotely(authorization));
    switch (result) {
      case Ok():
        _appLock.unlock();
      case Err(:final failure) when failure.code == FailureCodes.pinLocked:
        await _endSession();
      case Err():
        break;
    }
    return result;
  }

  @override
  Future<Result<OtpVerification>> verifyOtp(OtpChallenge challenge, String code) => guardApi(() async => (await _remote.verifyOtp(challenge.id, code)).toEntity());
}
