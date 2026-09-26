import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/utils/path_template.dart';
import '../../domain/entities/bank_link_challenge.dart';
import '../../domain/entities/card_details.dart';
import '../models/funding_source_model.dart';

class FundingRemoteDataSource {
  final ApiClient _client;

  const FundingRemoteDataSource(this._client);

  Future<FundingSourceModel> addCard(CardDetails details) async =>
      FundingSourceModel.fromJson(await _client.post(ApiPaths.fundingCard, body: {'cvv': details.cvv, 'expiryMonth': details.expiryMonth, 'expiryYear': details.expiryYear, 'number': details.number}));

  Future<List<FundingSourceModel>> getSources() async => [for (final item in (await _client.get(ApiPaths.fundingSources))['items'] as List<dynamic>) FundingSourceModel.fromJson(item as Map<String, dynamic>)];

  Future<BankLinkChallenge> linkBank(String bankCode, String accountNumber, String? branchCode) async {
    final json = await _client.post(ApiPaths.fundingBank, body: {'accountNumber': accountNumber, 'bankCode': bankCode, 'branchCode': ?branchCode});
    return BankLinkChallenge(codeLength: json['codeLength'] as int, expiresAt: DateTime.parse(json['expiresAt'] as String), id: json['challengeId'] as String);
  }

  Future<void> removeSource(String sourceId) => _client.delete(ApiPaths.fundingSource.withId(sourceId));

  Future<FundingSourceModel> verifyBankLink(String challengeId, String code) async => FundingSourceModel.fromJson(await _client.post(ApiPaths.fundingBankVerify, body: {'challengeId': challengeId, 'code': code}));
}
