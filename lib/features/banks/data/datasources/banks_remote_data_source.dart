import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/utils/path_template.dart';
import '../models/bank_account_model.dart';
import '../models/bank_branch_model.dart';
import '../models/bank_model.dart';
import '../models/bank_payee_model.dart';

class BanksRemoteDataSource {
  final ApiClient _client;

  const BanksRemoteDataSource(this._client);

  Future<void> deletePayee(String payeeId) => _client.delete(ApiPaths.bankPayee.withId(payeeId));

  Future<List<BankModel>> getBanks() async => [for (final item in (await _client.get(ApiPaths.banks))['items'] as List<dynamic>) BankModel.fromJson(item as Map<String, dynamic>)];

  Future<List<BankBranchModel>> getBranches(String bankCode) async => [for (final item in (await _client.get(ApiPaths.bankBranches.withId(bankCode)))['items'] as List<dynamic>) BankBranchModel.fromJson(item as Map<String, dynamic>)];

  Future<List<BankPayeeModel>> getPayees() async => [for (final item in (await _client.get(ApiPaths.bankPayees))['items'] as List<dynamic>) BankPayeeModel.fromJson(item as Map<String, dynamic>)];

  Future<BankAccountModel> lookupAccount(String bankCode, String accountNumber, String? branchCode) async =>
      BankAccountModel.fromJson(await _client.post(ApiPaths.bankAccountLookup, body: {'accountNumber': accountNumber, 'bankCode': bankCode, 'branchCode': ?branchCode}));

  Future<BankPayeeModel> savePayee(String bankCode, String accountNumber, String? branchCode, String nickname) async =>
      BankPayeeModel.fromJson(await _client.post(ApiPaths.bankPayees, body: {'accountNumber': accountNumber, 'bankCode': bankCode, 'branchCode': ?branchCode, 'nickname': nickname}));
}
