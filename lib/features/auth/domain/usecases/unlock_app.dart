import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../repositories/auth_repository.dart';

class UnlockApp {
  final AuthRepository _repository;

  const UnlockApp(this._repository);

  Future<Result<void>> call(Authorization authorization) => _repository.unlock(authorization);
}
