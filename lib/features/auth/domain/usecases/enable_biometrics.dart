import '../../../../core/errors/result.dart';
import '../repositories/biometric_repository.dart';

class EnableBiometrics {
  final BiometricRepository _repository;

  const EnableBiometrics(this._repository);

  Future<Result<void>> call(String pin) => _repository.enable(pin);
}
