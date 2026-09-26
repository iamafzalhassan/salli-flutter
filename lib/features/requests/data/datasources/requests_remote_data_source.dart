import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/utils/path_template.dart';
import '../models/money_request_model.dart';
import '../models/split_model.dart';

class RequestsRemoteDataSource {
  final ApiClient _client;

  const RequestsRemoteDataSource(this._client);

  Future<MoneyRequestModel> cancel(String requestId) async => MoneyRequestModel.fromJson(await _client.post(ApiPaths.moneyRequestCancel.withId(requestId)));

  Future<MoneyRequestModel> create(String phone, int amountCents, String? note) async => MoneyRequestModel.fromJson(await _client.post(ApiPaths.moneyRequests, body: {'amountCents': amountCents, 'note': ?note, 'phone': phone}));

  Future<SplitModel> createSplit(int totalCents, String? note, List<String> phones, {required bool includeSelf}) async =>
      SplitModel.fromJson(await _client.post(ApiPaths.splits, body: {'amountCents': totalCents, 'includeSelf': includeSelf, 'note': ?note, 'phones': phones}));

  Future<MoneyRequestModel> decline(String requestId) async => MoneyRequestModel.fromJson(await _client.post(ApiPaths.moneyRequestDecline.withId(requestId)));

  Future<List<MoneyRequestModel>> getRequests() async => [for (final item in (await _client.get(ApiPaths.moneyRequests))['items'] as List<dynamic>) MoneyRequestModel.fromJson(item as Map<String, dynamic>)];

  Future<List<SplitModel>> getSplits() async => [for (final item in (await _client.get(ApiPaths.splits))['items'] as List<dynamic>) SplitModel.fromJson(item as Map<String, dynamic>)];

  Future<MoneyRequestModel> remind(String requestId) async => MoneyRequestModel.fromJson(await _client.post(ApiPaths.moneyRequestRemind.withId(requestId)));
}
