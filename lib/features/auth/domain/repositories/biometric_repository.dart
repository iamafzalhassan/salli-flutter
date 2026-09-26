import '../../../../core/errors/result.dart';
import '../entities/biometric_status.dart';

abstract interface class BiometricRepository {
  Future<void> disable();

  Future<Result<void>> enable(String pin);

  Future<BiometricStatus> status();
}
