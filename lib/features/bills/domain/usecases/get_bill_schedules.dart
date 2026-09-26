import '../../../../core/errors/result.dart';
import '../entities/bill_schedule.dart';
import '../repositories/bills_repository.dart';

class GetBillSchedules {
  final BillsRepository _repository;

  const GetBillSchedules(this._repository);

  Future<Result<List<BillSchedule>>> call() => _repository.getSchedules();
}
