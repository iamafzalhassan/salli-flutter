import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_checkout.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/modules/banks_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/utils/path_template.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const boc = '7010';
  const account = '0012345678';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  Future<MockResponse> lookup({String accountNumber = account, String bankCode = boc, String? branchCode}) =>
      harness.authorized('POST', ApiPaths.bankAccountLookup, session, body: {'accountNumber': accountNumber, 'bankCode': bankCode, 'branchCode': ?branchCode});

  Future<MockResponse> transfer(int amountCents, {String key = 'key-1', String pinHash = 'hash-a'}) => harness.authorized(
    'POST',
    ApiPaths.bankTransfers,
    session,
    body: {
      'accountNumber': account,
      'amountCents': amountCents,
      'approval': {'method': Approver.pinMethod, 'pinHash': pinHash},
      'bankCode': boc,
    },
    headers: {ApiHeaders.idempotencyKey: key},
  );

  Future<int> balance() async => (await harness.authorized('GET', ApiPaths.wallet, session)).body['balanceCents'] as int;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  test('lists the banks with their account formats and the transfer fee', () async {
    final items = (await harness.authorized('GET', ApiPaths.banks, session)).body['items'] as List<dynamic>;
    expect(items, hasLength(BanksMockModule.directory.length));
    expect((items.first as Map<String, dynamic>)['feeCents'], BanksMockModule.feeCents);
  });

  test('lists branches only for the banks that need one', () async {
    expect((await harness.authorized('GET', ApiPaths.bankBranches.withId('7135'), session)).body['items'], isNotEmpty);
    expect((await harness.authorized('GET', ApiPaths.bankBranches.withId(boc), session)).body['items'], isEmpty);
  });

  group('name enquiry', () {
    test('names the holder of the same account every time', () async {
      final first = await lookup();
      expect(first.statusCode, 200);
      expect(first.body['accountName'], (await lookup()).body['accountName']);
    });

    test('rejects a number in the wrong format for the bank', () async => expect(MockApiHarness.errorCode(await lookup(accountNumber: '12')), FailureCodes.invalidAccountNumber));

    test('reports an account that does not exist', () async => expect(MockApiHarness.errorCode(await lookup(accountNumber: '0012345000')), FailureCodes.bankAccountNotFound));

    test('needs a branch where the bank requires one', () async {
      expect(MockApiHarness.errorCode(await lookup(accountNumber: '123456789012345', bankCode: '7135')), FailureCodes.invalidRequest);
      expect((await lookup(accountNumber: '123456789012345', bankCode: '7135', branchCode: '024')).statusCode, 200);
    });
  });

  group('POST /v1/bank-transfers', () {
    test('charges the amount plus the CEFTS fee, posted as its own fee transaction', () async {
      final startingBalance = await balance();
      final response = await transfer(100000);
      expect(response.statusCode, 201);
      expect(response.body['feeCents'], BanksMockModule.feeCents);
      expect(await balance(), startingBalance - 100000 - BanksMockModule.feeCents);
      final items = ((await harness.authorized('GET', ApiPaths.transactions, session)).body['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(items.where((item) => item['type'] == MockCheckout.feeType).single['amountCents'], -BanksMockModule.feeCents);
    });

    test('counts the fee against the balance', () async {
      final startingBalance = await balance();
      expect(MockApiHarness.errorCode(await transfer(startingBalance - BanksMockModule.feeCents + 1)), FailureCodes.insufficientFunds);
    });

    test('rejects a wrong PIN without moving money', () async {
      final startingBalance = await balance();
      expect(MockApiHarness.errorCode(await transfer(10000, pinHash: 'hash-b')), FailureCodes.pinInvalid);
      expect(await balance(), startingBalance);
    });
  });

  group('bank payees', () {
    Future<MockResponse> save() => harness.authorized('POST', ApiPaths.bankPayees, session, body: {'accountNumber': account, 'bankCode': boc, 'nickname': 'Amma'});

    test('saves the account with the holder name from the enquiry', () async {
      final saved = await save();
      expect(saved.statusCode, 201);
      expect(saved.body['accountName'], (await lookup()).body['accountName']);
      expect(MockApiHarness.errorCode(await save()), FailureCodes.bankPayeeExists);
    });

    test('removes a saved account', () async {
      final id = (await save()).body['id'] as String;
      expect((await harness.authorized('DELETE', ApiPaths.bankPayee.withId(id), session)).statusCode, 204);
      expect((await harness.authorized('GET', ApiPaths.bankPayees, session)).body['items'], isEmpty);
    });
  });
}
