import '../../../../core/errors/result.dart';
import '../entities/money_request.dart';
import '../repositories/requests_repository.dart';

class CancelRequest {
  final RequestsRepository _repository;

  const CancelRequest(this._repository);

  Future<Result<MoneyRequest>> call(String requestId) => _repository.cancel(requestId);
}
