import '../../../../core/errors/result.dart';
import '../repositories/bills_repository.dart';

class DeleteSavedBiller {
  final BillsRepository _repository;

  const DeleteSavedBiller(this._repository);

  Future<Result<void>> call(String savedBillerId) => _repository.deleteSavedBiller(savedBillerId);
}
