import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/utils/path_template.dart';
import '../../domain/entities/dispute_reason.dart';
import '../../domain/entities/transaction_filter.dart';
import '../models/dispute_model.dart';
import '../models/monthly_insights_model.dart';
import '../models/transaction_detail_model.dart';
import '../models/transaction_filter_model.dart';
import '../models/transaction_page_model.dart';
import '../models/wallet_model.dart';

class WalletRemoteDataSource {
  final ApiClient _client;

  const WalletRemoteDataSource(this._client);

  Future<MonthlyInsightsModel> getInsights(DateTime month) async => MonthlyInsightsModel.fromJson(await _client.get(ApiPaths.insights, query: {'month': '${month.year}-${month.month.toString().padLeft(2, '0')}'}));

  Future<TransactionDetailModel> getTransaction(String id) async => TransactionDetailModel.fromJson(await _client.get(ApiPaths.transaction.withId(id)));

  Future<TransactionPageModel> getTransactions({String? cursor, required int limit, TransactionFilter filter = const TransactionFilter()}) async =>
      TransactionPageModel.fromJson(await _client.get(ApiPaths.transactions, query: {'cursor': ?cursor, 'limit': limit, ...TransactionFilterModel(filter).toQuery()}));

  Future<WalletModel> getWallet() async => WalletModel.fromJson(await _client.get(ApiPaths.wallet));

  Future<DisputeModel> reportProblem(String transactionId, DisputeReason reason, String? details) async =>
      DisputeModel.fromJson(await _client.post(ApiPaths.transactionDisputes.withId(transactionId), body: {'details': ?details, 'reason': DisputeModel.apiName(reason)}));
}
