import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/events/app_event.dart';
import 'package:salli/core/events/app_events.dart';
import 'package:salli/core/security/approval_payload.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/security/authorization.dart';
import 'package:salli/core/utils/lanka_qr.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/payments/data/datasources/payments_remote_data_source.dart';
import 'package:salli/features/payments/data/models/bank_transfer_request_model.dart';
import 'package:salli/features/payments/data/models/bill_payment_request_model.dart';
import 'package:salli/features/payments/data/models/funding_request_model.dart';
import 'package:salli/features/payments/data/models/merchant_lookup_model.dart';
import 'package:salli/features/payments/data/models/merchant_model.dart';
import 'package:salli/features/payments/data/models/merchant_payment_receipt_model.dart';
import 'package:salli/features/payments/data/models/merchant_payment_request_model.dart';
import 'package:salli/features/payments/data/models/payee_model.dart';
import 'package:salli/features/payments/data/models/payment_receipt_model.dart';
import 'package:salli/features/payments/data/models/reload_request_model.dart';
import 'package:salli/features/payments/data/models/transfer_receipt_model.dart';
import 'package:salli/features/payments/data/models/transfer_request_model.dart';
import 'package:salli/features/payments/data/repositories/payments_repository_impl.dart';
import 'package:salli/features/payments/domain/entities/payment_draft.dart';
import 'package:salli/features/payments/domain/entities/payment_receipt.dart';
import 'package:salli/features/payments/domain/entities/recipient.dart';
import 'package:salli/features/payments/domain/entities/scanned_code.dart';

const MerchantModel _keells = MerchantModel(category: 'grocery', city: 'Colombo 07', id: 'LKQR00000001', name: 'Keells Super');

class _FakeApprover implements Approver {
  final List<List<int>> payloads = [];

  @override
  Future<Map<String, dynamic>> approve(Authorization authorization, List<int> payload) async {
    payloads.add(payload);
    return {'method': Approver.pinMethod, 'pinHash': 'hash'};
  }
}

class _FakeRemote implements PaymentsRemoteDataSource {
  final List<MerchantPaymentRequestModel> merchantPayments = [];

  final List<String> idempotencyKeys = [];
  final List<String> merchantLookups = [];
  final List<String> phoneLookups = [];

  @override
  Future<Map<String, dynamic>> assessRisk(Map<String, dynamic> body) async => const {'reasons': <String>[]};

  @override
  Future<PaymentReceiptModel> bankTransfer(BankTransferRequestModel request, {required String idempotencyKey}) => throw UnimplementedError();

  @override
  Future<List<PayeeModel>> getRecentPayees() async => const [];

  @override
  Future<MerchantLookupModel> lookupMerchant(String qr) async {
    merchantLookups.add(qr);
    return const MerchantLookupModel(merchant: _keells);
  }

  @override
  Future<PayeeModel> lookupPayee(String phone) async {
    phoneLookups.add(phone);
    return PayeeModel(name: 'Fathima Rizna', phone: phone);
  }

  @override
  Future<PaymentReceiptModel> payBill(BillPaymentRequestModel request, {required String idempotencyKey}) => throw UnimplementedError();

  @override
  Future<MerchantPaymentReceiptModel> payMerchant(MerchantPaymentRequestModel request, {required String idempotencyKey}) async {
    idempotencyKeys.add(idempotencyKey);
    merchantPayments.add(request);
    return MerchantPaymentReceiptModel(amountCents: request.amountCents, createdAt: DateTime.utc(2026, 9, 21), feeCents: 0, id: 'tx', merchant: _keells, reference: 'SAL0000000001');
  }

  @override
  Future<PaymentReceiptModel> reload(ReloadRequestModel request, {required String idempotencyKey}) => throw UnimplementedError();

  @override
  Future<TransferReceiptModel> sendTransfer(TransferRequestModel request, {required String idempotencyKey}) => throw UnimplementedError();

  @override
  Future<PaymentReceiptModel> topUp(FundingRequestModel request, {required String idempotencyKey}) => throw UnimplementedError();

  @override
  Future<PaymentReceiptModel> withdraw(FundingRequestModel request, {required String idempotencyKey}) => throw UnimplementedError();
}

void main() {
  const keells = LankaQr(accountId: 'LKQR00000001', categoryCode: '5411', city: 'Colombo 07', guid: LankaQr.merchantGuid, isDynamic: false, name: 'Keells Super');

  late AppEvents events;
  late _FakeApprover approver;
  late _FakeRemote remote;
  late PaymentsRepositoryImpl repository;

  Matcher failsWith(String code) => isA<Err<ScannedCode>>().having((err) => err.failure, 'failure', Failure(code));

  setUp(() {
    events = AppEvents();
    approver = _FakeApprover();
    remote = _FakeRemote();
    repository = PaymentsRepositoryImpl(events, approver, remote);
  });

  group('resolveCode', () {
    test('asks the server about a merchant code, sending it without surrounding whitespace', () async {
      final result = await repository.resolveCode('  ${keells.encode()}\n');
      expect(remote.merchantLookups, [keells.encode()]);
      expect(
        result,
        isA<Ok<ScannedCode>>().having(
          (ok) => ok.value,
          'value',
          ScannedCode(
            recipient: MerchantRecipient(merchant: _keells.toEntity(), qr: keells.encode()),
          ),
        ),
      );
    });

    test('looks up the person behind a personal code and keeps its amount', () async {
      final result = await repository.resolveCode(const LankaQr.personal(amount: Money.rupees(500), name: 'Fathima', phone: '+94704445566').encode());
      expect(remote.phoneLookups, ['+94704445566']);
      expect(result, isA<Ok<ScannedCode>>().having((ok) => ok.value.amount, 'amount', const Money.rupees(500)));
    });

    test('rejects a tampered code without calling the server', () async {
      expect(await repository.resolveCode(keells.encode().replaceFirst('Keells', 'Kee11s')), failsWith(FailureCodes.invalidQr));
      expect(remote.merchantLookups, isEmpty);
    });

    test('rejects a personal code that does not hold a Sri Lankan mobile number', () async {
      expect(await repository.resolveCode(const LankaQr.personal(name: 'Someone', phone: '+15550100').encode()), failsWith(FailureCodes.invalidQr));
      expect(remote.phoneLookups, isEmpty);
    });

    test('explains a code for another currency', () async {
      final foreign = keells.encode().replaceFirst('5303144', '5303840');
      final data = foreign.substring(0, foreign.length - 4);
      final repaired = '$data${LankaQr.crc16(utf8.encode(data)).toRadixString(16).toUpperCase().padLeft(4, '0')}';
      expect(await repository.resolveCode(repaired), failsWith(FailureCodes.unsupportedCurrency));
    });
  });

  group('sendPayment', () {
    test('pays a merchant with an approval bound to the merchant, the amount and the idempotency key', () async {
      final published = <AppEvent>[];
      events.stream.listen(published.add);
      final recipient = MerchantRecipient(merchant: _keells.toEntity(), qr: keells.encode());
      final result = await repository.sendPayment(PaymentDraft(amount: const Money(125050), idempotencyKey: 'key', recipient: recipient), const PinAuthorization('482915'));
      expect(result, isA<Ok<PaymentReceipt>>());
      expect(approver.payloads.single, ApprovalPayload.merchantPayment(amountCents: 125050, idempotencyKey: 'key', merchantId: 'LKQR00000001'));
      expect(remote.merchantPayments.single.qr, keells.encode());
      expect(remote.idempotencyKeys, ['key']);
      await Future<void>.delayed(Duration.zero);
      expect(published.single, isA<WalletChanged>());
    });

    test('the receipt names the merchant that was paid', () async {
      final recipient = MerchantRecipient(merchant: _keells.toEntity(), qr: keells.encode());
      final result = await repository.sendPayment(PaymentDraft(amount: const Money(100), idempotencyKey: 'key', recipient: recipient), const PinAuthorization('482915'));
      expect(result, isA<Ok<PaymentReceipt>>().having((ok) => ok.value.recipient, 'recipient', recipient));
    });
  });
}
