import '../../../../core/errors/result.dart';
import '../entities/bank.dart';
import '../entities/bank_account.dart';
import '../repositories/banks_repository.dart';

class LookupBankAccount {
  final BanksRepository _repository;

  const LookupBankAccount(this._repository);

  Future<Result<BankAccount>> call(Bank bank, String accountNumber, {String? branchCode}) => _repository.lookupAccount(bank, accountNumber, branchCode: branchCode);
}
