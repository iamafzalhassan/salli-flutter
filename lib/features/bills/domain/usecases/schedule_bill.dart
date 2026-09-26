import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../entities/bill_schedule.dart';
import '../entities/saved_biller.dart';
import '../repositories/bills_repository.dart';

class ScheduleBill {
  final BillsRepository _repository;

  const ScheduleBill(this._repository);

  Future<Result<BillSchedule>> call(SavedBiller savedBiller, int dayOfMonth, {Authorization? autopayAuthorization}) => _repository.schedule(savedBiller, dayOfMonth, autopayAuthorization);
}
