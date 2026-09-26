import '../../../../core/errors/result.dart';
import '../entities/biller.dart';
import '../entities/saved_biller.dart';
import '../repositories/bills_repository.dart';

class SaveBiller {
  final BillsRepository _repository;

  const SaveBiller(this._repository);

  Future<Result<SavedBiller>> call(Biller biller, String accountNumber, String nickname) => _repository.saveBiller(biller, accountNumber, nickname);
}
