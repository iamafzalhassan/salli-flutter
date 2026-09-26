import '../../../../core/errors/result.dart';
import '../entities/security_event.dart';
import '../entities/trusted_device.dart';

abstract interface class SecurityRepository {
  Future<Result<void>> changePin(String currentPin, String newPin);

  Future<Result<List<TrustedDevice>>> getDevices();

  Future<Result<List<SecurityEvent>>> getEvents();
}
