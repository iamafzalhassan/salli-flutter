import '../../../../core/errors/result.dart';
import '../entities/bill_split.dart';
import '../repositories/requests_repository.dart';

class GetSplits {
  final RequestsRepository _repository;

  const GetSplits(this._repository);

  Future<Result<List<BillSplit>>> call() => _repository.getSplits();
}
