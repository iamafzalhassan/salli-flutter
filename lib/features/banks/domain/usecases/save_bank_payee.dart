import '../../../../core/errors/result.dart';
import '../entities/bank_account.dart';
import '../entities/bank_payee.dart';
import '../repositories/banks_repository.dart';

class SaveBankPayee {
  final BanksRepository _repository;

  const SaveBankPayee(this._repository);

  Future<Result<BankPayee>> call(BankAccount account, String nickname) => _repository.savePayee(account, nickname);
}
