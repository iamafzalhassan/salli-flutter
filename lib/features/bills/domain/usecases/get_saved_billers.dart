import '../../../../core/errors/result.dart';
import '../entities/saved_biller.dart';
import '../repositories/bills_repository.dart';

class GetSavedBillers {
  final BillsRepository _repository;

  const GetSavedBillers(this._repository);

  Future<Result<List<SavedBiller>>> call() => _repository.getSavedBillers();
}
