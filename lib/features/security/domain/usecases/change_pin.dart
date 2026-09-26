import '../../../../core/errors/result.dart';
import '../repositories/security_repository.dart';

class ChangePin {
  final SecurityRepository _repository;

  const ChangePin(this._repository);

  Future<Result<void>> call(String currentPin, String newPin) => _repository.changePin(currentPin, newPin);
}
