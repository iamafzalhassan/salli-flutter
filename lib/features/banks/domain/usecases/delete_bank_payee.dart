import '../../../../core/errors/result.dart';
import '../repositories/banks_repository.dart';

class DeleteBankPayee {
  final BanksRepository _repository;

  const DeleteBankPayee(this._repository);

  Future<Result<void>> call(String payeeId) => _repository.deletePayee(payeeId);
}
