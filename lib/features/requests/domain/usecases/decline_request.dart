import '../../../../core/errors/result.dart';
import '../entities/money_request.dart';
import '../repositories/requests_repository.dart';

class DeclineRequest {
  final RequestsRepository _repository;

  const DeclineRequest(this._repository);

  Future<Result<MoneyRequest>> call(String requestId) => _repository.decline(requestId);
}
