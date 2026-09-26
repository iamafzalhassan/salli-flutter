import '../../../../core/errors/result.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../entities/bill_split.dart';
import '../repositories/requests_repository.dart';

class CreateSplit {
  final RequestsRepository _repository;

  const CreateSplit(this._repository);

  Future<Result<BillSplit>> call(Money total, String? note, List<PhoneNumber> phones, {required bool includeSelf}) => _repository.createSplit(total, note, phones, includeSelf: includeSelf);
}
