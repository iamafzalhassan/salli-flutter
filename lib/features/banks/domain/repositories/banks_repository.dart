import '../../../../core/errors/result.dart';
import '../entities/bank.dart';
import '../entities/bank_account.dart';
import '../entities/bank_branch.dart';
import '../entities/bank_payee.dart';

abstract interface class BanksRepository {
  Future<Result<void>> deletePayee(String payeeId);

  Future<Result<List<Bank>>> getBanks();

  Future<Result<List<BankBranch>>> getBranches(Bank bank);

  Future<Result<List<BankPayee>>> getPayees();

  Future<Result<BankAccount>> lookupAccount(Bank bank, String accountNumber, {String? branchCode});

  Future<Result<BankPayee>> savePayee(BankAccount account, String nickname);
}
