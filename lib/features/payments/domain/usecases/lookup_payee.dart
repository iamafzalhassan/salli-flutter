import '../../../../core/errors/result.dart';
import '../../../../core/utils/phone_number.dart';
import '../entities/payee.dart';
import '../repositories/payments_repository.dart';

class LookupPayee {
  final PaymentsRepository _repository;

  const LookupPayee(this._repository);

  Future<Result<Payee>> call(PhoneNumber phone) => _repository.lookupPayee(phone);
}
