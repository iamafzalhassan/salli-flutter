import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../entities/bill.dart';
import '../entities/bill_schedule.dart';
import '../entities/biller.dart';
import '../entities/saved_biller.dart';

abstract interface class BillsRepository {
  Future<Result<void>> cancelSchedule(String scheduleId);

  Future<Result<void>> deleteSavedBiller(String savedBillerId);

  Future<Result<List<Biller>>> getBillers();

  Future<Result<List<SavedBiller>>> getSavedBillers();

  Future<Result<List<BillSchedule>>> getSchedules();

  Future<Result<Bill>> inquire(Biller biller, String accountNumber);

  Future<Result<SavedBiller>> renameSavedBiller(String savedBillerId, String nickname);

  Future<Result<SavedBiller>> saveBiller(Biller biller, String accountNumber, String nickname);

  Future<Result<BillSchedule>> schedule(SavedBiller savedBiller, int dayOfMonth, Authorization? autopayAuthorization);
}
