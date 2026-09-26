import '../../../../core/errors/result.dart';
import '../entities/money_request.dart';
import '../repositories/requests_repository.dart';

class GetRequests {
  final RequestsRepository _repository;

  const GetRequests(this._repository);

  Future<Result<List<MoneyRequest>>> call() => _repository.getRequests();
}
