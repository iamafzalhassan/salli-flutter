import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/bank_transfer_request_model.dart';
import '../models/bill_payment_request_model.dart';
import '../models/funding_request_model.dart';
import '../models/merchant_lookup_model.dart';
import '../models/merchant_payment_receipt_model.dart';
import '../models/merchant_payment_request_model.dart';
import '../models/payee_model.dart';
import '../models/payment_receipt_model.dart';
import '../models/reload_request_model.dart';
import '../models/transfer_receipt_model.dart';
import '../models/transfer_request_model.dart';

class PaymentsRemoteDataSource {
  final ApiClient _client;

  const PaymentsRemoteDataSource(this._client);

  Future<Map<String, dynamic>> assessRisk(Map<String, dynamic> body) => _client.post(ApiPaths.paymentRisk, body: body);

  Future<PaymentReceiptModel> bankTransfer(BankTransferRequestModel request, {required String idempotencyKey}) async =>
      PaymentReceiptModel.fromJson(await _client.post(ApiPaths.bankTransfers, body: request.toJson(), idempotencyKey: idempotencyKey));

  Future<List<PayeeModel>> getRecentPayees() async => [for (final item in (await _client.get(ApiPaths.recentPayees))['items'] as List<dynamic>) PayeeModel.fromJson(item as Map<String, dynamic>)];

  Future<MerchantLookupModel> lookupMerchant(String qr) async => MerchantLookupModel.fromJson(await _client.post(ApiPaths.merchantLookup, body: {'qr': qr}));

  Future<PayeeModel> lookupPayee(String phone) async => PayeeModel.fromJson(await _client.get(ApiPaths.payeeLookup, query: {'phone': phone}));

  Future<PaymentReceiptModel> payBill(BillPaymentRequestModel request, {required String idempotencyKey}) async =>
      PaymentReceiptModel.fromJson(await _client.post(ApiPaths.billPayments, body: request.toJson(), idempotencyKey: idempotencyKey));

  Future<MerchantPaymentReceiptModel> payMerchant(MerchantPaymentRequestModel request, {required String idempotencyKey}) async =>
      MerchantPaymentReceiptModel.fromJson(await _client.post(ApiPaths.merchantPayments, body: request.toJson(), idempotencyKey: idempotencyKey));

  Future<PaymentReceiptModel> reload(ReloadRequestModel request, {required String idempotencyKey}) async => PaymentReceiptModel.fromJson(await _client.post(ApiPaths.reloads, body: request.toJson(), idempotencyKey: idempotencyKey));

  Future<TransferReceiptModel> sendTransfer(TransferRequestModel request, {required String idempotencyKey}) async =>
      TransferReceiptModel.fromJson(await _client.post(ApiPaths.transfers, body: request.toJson(), idempotencyKey: idempotencyKey));

  Future<PaymentReceiptModel> topUp(FundingRequestModel request, {required String idempotencyKey}) async => PaymentReceiptModel.fromJson(await _client.post(ApiPaths.topUps, body: request.toJson(), idempotencyKey: idempotencyKey));

  Future<PaymentReceiptModel> withdraw(FundingRequestModel request, {required String idempotencyKey}) async => PaymentReceiptModel.fromJson(await _client.post(ApiPaths.withdrawals, body: request.toJson(), idempotencyKey: idempotencyKey));
}
