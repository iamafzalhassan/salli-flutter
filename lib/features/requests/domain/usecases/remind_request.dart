import '../../../../core/errors/result.dart';
import '../entities/money_request.dart';
import '../repositories/requests_repository.dart';

class RemindRequest {
  final RequestsRepository _repository;

  const RemindRequest(this._repository);

  Future<Result<MoneyRequest>> call(String requestId) => _repository.remind(requestId);
}
