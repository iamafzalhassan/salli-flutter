import '../../../../core/errors/result.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../entities/bill_split.dart';
import '../entities/money_request.dart';

abstract interface class RequestsRepository {
  Future<Result<MoneyRequest>> cancel(String requestId);

  Future<Result<MoneyRequest>> create(PhoneNumber phone, Money amount, String? note);

  Future<Result<BillSplit>> createSplit(Money total, String? note, List<PhoneNumber> phones, {required bool includeSelf});

  Future<Result<MoneyRequest>> decline(String requestId);

  Future<Result<List<MoneyRequest>>> getRequests();

  Future<Result<List<BillSplit>>> getSplits();

  Future<Result<MoneyRequest>> remind(String requestId);
}
