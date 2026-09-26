import '../entities/biometric_status.dart';
import '../repositories/biometric_repository.dart';

class GetBiometricStatus {
  final BiometricRepository _repository;

  const GetBiometricStatus(this._repository);

  Future<BiometricStatus> call() => _repository.status();
}
