import '../repositories/biometric_repository.dart';

class DisableBiometrics {
  final BiometricRepository _repository;

  const DisableBiometrics(this._repository);

  Future<void> call() => _repository.disable();
}
