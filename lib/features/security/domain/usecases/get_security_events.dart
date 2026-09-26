import '../../../../core/errors/result.dart';
import '../entities/security_event.dart';
import '../repositories/security_repository.dart';

class GetSecurityEvents {
  final SecurityRepository _repository;

  const GetSecurityEvents(this._repository);

  Future<Result<List<SecurityEvent>>> call() => _repository.getEvents();
}
