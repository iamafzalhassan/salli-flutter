import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/utils/path_template.dart';
import '../models/bill_model.dart';
import '../models/bill_schedule_model.dart';
import '../models/biller_model.dart';
import '../models/saved_biller_model.dart';

class BillsRemoteDataSource {
  final ApiClient _client;

  const BillsRemoteDataSource(this._client);

  Future<void> cancelSchedule(String scheduleId) => _client.delete(ApiPaths.billSchedule.withId(scheduleId));

  Future<void> deleteSavedBiller(String savedBillerId) => _client.delete(ApiPaths.savedBiller.withId(savedBillerId));

  Future<List<BillerModel>> getBillers() async => [for (final item in (await _client.get(ApiPaths.billers))['items'] as List<dynamic>) BillerModel.fromJson(item as Map<String, dynamic>)];

  Future<List<SavedBillerModel>> getSavedBillers() async => [for (final item in (await _client.get(ApiPaths.savedBillers))['items'] as List<dynamic>) SavedBillerModel.fromJson(item as Map<String, dynamic>)];

  Future<List<BillScheduleModel>> getSchedules() async => [for (final item in (await _client.get(ApiPaths.billSchedules))['items'] as List<dynamic>) BillScheduleModel.fromJson(item as Map<String, dynamic>)];

  Future<BillModel> inquire(String billerId, String accountNumber) async => BillModel.fromJson(await _client.post(ApiPaths.billInquiry, body: {'accountNumber': accountNumber, 'billerId': billerId}));

  Future<SavedBillerModel> renameSavedBiller(String savedBillerId, String nickname) async => SavedBillerModel.fromJson(await _client.patch(ApiPaths.savedBiller.withId(savedBillerId), body: {'nickname': nickname}));

  Future<SavedBillerModel> saveBiller(String billerId, String accountNumber, String nickname) async =>
      SavedBillerModel.fromJson(await _client.post(ApiPaths.savedBillers, body: {'accountNumber': accountNumber, 'billerId': billerId, 'nickname': nickname}));

  Future<BillScheduleModel> schedule(Map<String, dynamic> body, {String? idempotencyKey}) async => BillScheduleModel.fromJson(await _client.post(ApiPaths.billSchedules, body: body, idempotencyKey: idempotencyKey));
}
