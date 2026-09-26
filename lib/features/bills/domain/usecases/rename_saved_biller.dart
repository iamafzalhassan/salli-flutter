import '../../../../core/errors/result.dart';
import '../entities/saved_biller.dart';
import '../repositories/bills_repository.dart';

class RenameSavedBiller {
  final BillsRepository _repository;

  const RenameSavedBiller(this._repository);

  Future<Result<SavedBiller>> call(String savedBillerId, String nickname) => _repository.renameSavedBiller(savedBillerId, nickname);
}
