import '../../../../core/errors/result.dart';
import '../entities/biller.dart';
import '../repositories/bills_repository.dart';

class GetBillers {
  final BillsRepository _repository;

  const GetBillers(this._repository);

  Future<Result<List<Biller>>> call() => _repository.getBillers();
}
