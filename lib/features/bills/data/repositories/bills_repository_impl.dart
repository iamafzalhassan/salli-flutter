import '../../../../core/errors/result.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/security/approval_payload.dart';
import '../../../../core/security/approver.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/bill.dart';
import '../../domain/entities/bill_schedule.dart';
import '../../domain/entities/biller.dart';
import '../../domain/entities/saved_biller.dart';
import '../../domain/repositories/bills_repository.dart';
import '../datasources/bills_remote_data_source.dart';

class BillsRepositoryImpl implements BillsRepository {
  final Approver _approver;

  final BillsRemoteDataSource _remote;

  const BillsRepositoryImpl(this._approver, this._remote);

  @override
  Future<Result<void>> cancelSchedule(String scheduleId) => guardApi(() => _remote.cancelSchedule(scheduleId));

  @override
  Future<Result<void>> deleteSavedBiller(String savedBillerId) => guardApi(() => _remote.deleteSavedBiller(savedBillerId));

  @override
  Future<Result<List<Biller>>> getBillers() => guardApi(() async => [for (final biller in await _remote.getBillers()) biller.toEntity()]);

  @override
  Future<Result<List<SavedBiller>>> getSavedBillers() => guardApi(() async => [for (final saved in await _remote.getSavedBillers()) saved.toEntity()]);

  @override
  Future<Result<List<BillSchedule>>> getSchedules() => guardApi(() async => [for (final schedule in await _remote.getSchedules()) schedule.toEntity()]);

  @override
  Future<Result<Bill>> inquire(Biller biller, String accountNumber) => guardApi(() async => (await _remote.inquire(biller.id, accountNumber)).toEntity());

  @override
  Future<Result<SavedBiller>> renameSavedBiller(String savedBillerId, String nickname) => guardApi(() async => (await _remote.renameSavedBiller(savedBillerId, nickname.trim())).toEntity());

  @override
  Future<Result<SavedBiller>> saveBiller(Biller biller, String accountNumber, String nickname) => guardApi(() async => (await _remote.saveBiller(biller.id, accountNumber, nickname.trim())).toEntity());

  @override
  Future<Result<BillSchedule>> schedule(SavedBiller savedBiller, int dayOfMonth, Authorization? autopayAuthorization) => guardApi(() async {
    final body = <String, dynamic>{'autopay': autopayAuthorization != null, 'dayOfMonth': dayOfMonth, 'savedBillerId': savedBiller.id};
    if (autopayAuthorization == null) return (await _remote.schedule(body)).toEntity();
    final idempotencyKey = IdGenerator.next();
    final payload = ApprovalPayload.billMandate(dayOfMonth: dayOfMonth, idempotencyKey: idempotencyKey, savedBillerId: savedBiller.id);
    return (await _remote.schedule({...body, 'approval': await _approver.approve(autopayAuthorization, payload)}, idempotencyKey: idempotencyKey)).toEntity();
  });
}
