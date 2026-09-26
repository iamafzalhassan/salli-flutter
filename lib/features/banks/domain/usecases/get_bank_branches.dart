import '../../../../core/errors/result.dart';
import '../entities/bank.dart';
import '../entities/bank_branch.dart';
import '../repositories/banks_repository.dart';

class GetBankBranches {
  final BanksRepository _repository;

  const GetBankBranches(this._repository);

  Future<Result<List<BankBranch>>> call(Bank bank) => _repository.getBranches(bank);
}
