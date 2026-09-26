import '../../../../core/errors/result.dart';
import '../repositories/bills_repository.dart';

class CancelBillSchedule {
  final BillsRepository _repository;

  const CancelBillSchedule(this._repository);

  Future<Result<void>> call(String scheduleId) => _repository.cancelSchedule(scheduleId);
}
