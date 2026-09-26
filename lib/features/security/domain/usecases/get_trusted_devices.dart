import '../../../../core/errors/result.dart';
import '../entities/trusted_device.dart';
import '../repositories/security_repository.dart';

class GetTrustedDevices {
  final SecurityRepository _repository;

  const GetTrustedDevices(this._repository);

  Future<Result<List<TrustedDevice>>> call() => _repository.getDevices();
}
