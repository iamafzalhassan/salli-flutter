import '../../../../core/errors/result.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/bill_split.dart';
import '../../domain/entities/money_request.dart';
import '../../domain/repositories/requests_repository.dart';
import '../datasources/requests_remote_data_source.dart';

class RequestsRepositoryImpl implements RequestsRepository {
  final RequestsRemoteDataSource _remote;

  const RequestsRepositoryImpl(this._remote);

  @override
  Future<Result<MoneyRequest>> cancel(String requestId) => guardApi(() async => (await _remote.cancel(requestId)).toEntity());

  @override
  Future<Result<MoneyRequest>> create(PhoneNumber phone, Money amount, String? note) => guardApi(() async => (await _remote.create(phone.e164, amount.cents, note)).toEntity());

  @override
  Future<Result<BillSplit>> createSplit(Money total, String? note, List<PhoneNumber> phones, {required bool includeSelf}) =>
      guardApi(() async => (await _remote.createSplit(total.cents, note, [for (final phone in phones) phone.e164], includeSelf: includeSelf)).toEntity());

  @override
  Future<Result<MoneyRequest>> decline(String requestId) => guardApi(() async => (await _remote.decline(requestId)).toEntity());

  @override
  Future<Result<List<MoneyRequest>>> getRequests() => guardApi(() async => [for (final request in await _remote.getRequests()) request.toEntity()]);

  @override
  Future<Result<List<BillSplit>>> getSplits() => guardApi(() async => [for (final split in await _remote.getSplits()) split.toEntity()]);

  @override
  Future<Result<MoneyRequest>> remind(String requestId) => guardApi(() async => (await _remote.remind(requestId)).toEntity());
}
