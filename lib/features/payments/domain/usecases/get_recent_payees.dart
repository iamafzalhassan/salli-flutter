import '../../../../core/errors/result.dart';
import '../entities/payee.dart';
import '../repositories/payments_repository.dart';

class GetRecentPayees {
  final PaymentsRepository _repository;

  const GetRecentPayees(this._repository);

  Future<Result<List<Payee>>> call() => _repository.getRecentPayees();
}
