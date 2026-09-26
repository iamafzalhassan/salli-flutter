import '../../../../core/errors/result.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../entities/money_request.dart';
import '../repositories/requests_repository.dart';

class CreateRequest {
  final RequestsRepository _repository;

  const CreateRequest(this._repository);

  Future<Result<MoneyRequest>> call(PhoneNumber phone, Money amount, String? note) => _repository.create(phone, amount, note);
}
