import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/account_limits_model.dart';
import '../models/verification_model.dart';

class AccountRemoteDataSource {
  final ApiClient _client;

  const AccountRemoteDataSource(this._client);

  Future<AccountLimitsModel> getLimits() async => AccountLimitsModel.fromJson(await _client.get(ApiPaths.limits));

  Future<VerificationModel> getVerification() async => VerificationModel.fromJson(await _client.get(ApiPaths.kyc));

  Future<VerificationModel> submitKyc(Map<String, dynamic> body) async => VerificationModel.fromJson(await _client.post(ApiPaths.kyc, body: body));
}
