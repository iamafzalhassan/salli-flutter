import '../../../../core/errors/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/security/biometric_vault.dart';
import '../../../../core/security/pin_credential.dart';
import '../../domain/entities/biometric_status.dart';
import '../../domain/repositories/biometric_repository.dart';
import '../datasources/biometric_remote_data_source.dart';

class BiometricRepositoryImpl implements BiometricRepository {
  final BiometricRemoteDataSource _remote;

  final BiometricVault _vault;

  final PinCredential _pinCredential;

  const BiometricRepositoryImpl(this._remote, this._vault, this._pinCredential);

  @override
  Future<void> disable() async {
    try {
      await _remote.remove();
    } on ApiException {
      return;
    } finally {
      await _vault.reset();
    }
  }

  @override
  Future<Result<void>> enable(String pin) => guardApi(() async {
    final pinHash = await _pinCredential.hash(pin);
    await _remote.enroll(pinHash: pinHash, publicKey: await _vault.createKey());
    await _vault.markEnabled();
  });

  @override
  Future<BiometricStatus> status() async => BiometricStatus(availability: await _vault.availability(), isEnabled: await _vault.isEnabled());
}
