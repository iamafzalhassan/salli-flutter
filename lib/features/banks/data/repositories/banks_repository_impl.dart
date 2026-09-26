import '../../../../core/errors/result.dart';
import '../../../../core/network/api_guard.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/bank_branch.dart';
import '../../domain/entities/bank_payee.dart';
import '../../domain/repositories/banks_repository.dart';
import '../datasources/banks_remote_data_source.dart';

class BanksRepositoryImpl implements BanksRepository {
  final BanksRemoteDataSource _remote;

  const BanksRepositoryImpl(this._remote);

  @override
  Future<Result<void>> deletePayee(String payeeId) => guardApi(() => _remote.deletePayee(payeeId));

  @override
  Future<Result<List<Bank>>> getBanks() => guardApi(() async => [for (final bank in await _remote.getBanks()) bank.toEntity()]);

  @override
  Future<Result<List<BankBranch>>> getBranches(Bank bank) => guardApi(() async => [for (final branch in await _remote.getBranches(bank.code)) branch.toEntity()]);

  @override
  Future<Result<List<BankPayee>>> getPayees() => guardApi(() async => [for (final payee in await _remote.getPayees()) payee.toEntity()]);

  @override
  Future<Result<BankAccount>> lookupAccount(Bank bank, String accountNumber, {String? branchCode}) => guardApi(() async => (await _remote.lookupAccount(bank.code, accountNumber, branchCode)).toEntity());

  @override
  Future<Result<BankPayee>> savePayee(BankAccount account, String nickname) => guardApi(() async => (await _remote.savePayee(account.bank.code, account.accountNumber, account.branchCode, nickname.trim())).toEntity());
}
