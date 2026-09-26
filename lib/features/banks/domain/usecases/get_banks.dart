import '../../../../core/errors/result.dart';
import '../entities/bank.dart';
import '../repositories/banks_repository.dart';

class GetBanks {
  final BanksRepository _repository;

  const GetBanks(this._repository);

  Future<Result<List<Bank>>> call() => _repository.getBanks();
}
