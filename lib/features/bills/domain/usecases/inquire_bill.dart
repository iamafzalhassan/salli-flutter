import '../../../../core/errors/result.dart';
import '../entities/bill.dart';
import '../entities/biller.dart';
import '../repositories/bills_repository.dart';

class InquireBill {
  final BillsRepository _repository;

  const InquireBill(this._repository);

  Future<Result<Bill>> call(Biller biller, String accountNumber) => _repository.inquire(biller, accountNumber);
}
