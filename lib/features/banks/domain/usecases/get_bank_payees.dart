import '../../../../core/errors/result.dart';
import '../entities/bank_payee.dart';
import '../repositories/banks_repository.dart';

class GetBankPayees {
  final BanksRepository _repository;

  const GetBankPayees(this._repository);

  Future<Result<List<BankPayee>>> call() => _repository.getPayees();
}
