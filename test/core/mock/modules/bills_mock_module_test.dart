import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/modules/bills_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/utils/path_template.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const account = '0123456789';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  Future<MockResponse> inquire({String accountNumber = account, String billerId = 'ceb'}) => harness.authorized('POST', ApiPaths.billInquiry, session, body: {'accountNumber': accountNumber, 'billerId': billerId});

  Future<int> amountDue() async => (await inquire()).body['amountDueCents'] as int;

  Future<MockResponse> pay(int amountCents, {String accountNumber = account, String billerId = 'ceb', String key = 'key-1', String pinHash = 'hash-a'}) => harness.authorized(
    'POST',
    ApiPaths.billPayments,
    session,
    body: {
      'accountNumber': accountNumber,
      'amountCents': amountCents,
      'approval': {'method': Approver.pinMethod, 'pinHash': pinHash},
      'billerId': billerId,
    },
    headers: {ApiHeaders.idempotencyKey: key},
  );

  Future<MockResponse> save({String accountNumber = account, String nickname = 'Home'}) => harness.authorized('POST', ApiPaths.savedBillers, session, body: {'accountNumber': accountNumber, 'billerId': 'ceb', 'nickname': nickname});

  Future<int> balance() async => (await harness.authorized('GET', ApiPaths.wallet, session)).body['balanceCents'] as int;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  group('GET /v1/billers', () {
    test('lists every biller with its account format', () async {
      final items = (await harness.authorized('GET', ApiPaths.billers, session)).body['items'] as List<dynamic>;
      expect(items, hasLength(BillsMockModule.directory.length));
      expect((items.first as Map<String, dynamic>).keys, containsAll(['accountHint', 'accountKind', 'accountPattern', 'category', 'id', 'name']));
    });
  });

  group('POST /v1/bills/inquiry', () {
    test('returns the same bill for the same account every time', () async {
      final first = await inquire();
      final second = await inquire();
      expect(first.statusCode, 200);
      expect(first.body['amountDueCents'], second.body['amountDueCents']);
      expect(first.body['customerName'], isNotEmpty);
    });

    test('rejects an account that does not match the biller format', () async => expect(MockApiHarness.errorCode(await inquire(accountNumber: '12345')), FailureCodes.invalidAccountNumber));

    test('reports an account that has no bill', () async => expect(MockApiHarness.errorCode(await inquire(accountNumber: '0123450000')), FailureCodes.billAccountNotFound));

    test('rejects an unknown biller', () async => expect(MockApiHarness.errorCode(await inquire(billerId: 'nope')), FailureCodes.billerNotFound));
  });

  group('POST /v1/bill-payments', () {
    test('pays the biller and lowers the amount due', () async {
      final before = await amountDue();
      final startingBalance = await balance();
      final response = await pay(10000);
      expect(response.statusCode, 201);
      expect((response.body['biller'] as Map<String, dynamic>)['id'], 'ceb');
      expect(await amountDue(), before - 10000);
      expect(await balance(), startingBalance - 10000);
    });

    test('shows up in activity as a bill payment', () async {
      await pay(10000);
      final latest = ((await harness.authorized('GET', ApiPaths.transactions, session)).body['items'] as List<dynamic>).first as Map<String, dynamic>;
      expect(latest['type'], BillsMockModule.transactionType);
      expect(latest['counterpartyName'], BillsMockModule.directory['ceb']!.name);
    });

    test('rejects a wrong PIN without moving money', () async {
      final startingBalance = await balance();
      expect(MockApiHarness.errorCode(await pay(10000, pinHash: 'hash-b')), FailureCodes.pinInvalid);
      expect(await balance(), startingBalance);
    });

    test('holds a leasing instalment above the basic single payment limit', () async {
      await harness.fund(session, 10000000);
      expect(MockApiHarness.errorCode(await pay(3000000, accountNumber: 'LBF1234567', billerId: 'lb_finance')), FailureCodes.limitExceeded);
    });
  });

  group('saved billers', () {
    test('saves, renames and removes a biller', () async {
      final created = await save();
      expect(created.statusCode, 201);
      final id = created.body['id'] as String;
      expect((await harness.authorized('PATCH', ApiPaths.savedBiller.withId(id), session, body: {'nickname': 'Office'})).body['nickname'], 'Office');
      expect((await harness.authorized('DELETE', ApiPaths.savedBiller.withId(id), session)).statusCode, 204);
      expect((await harness.authorized('GET', ApiPaths.savedBillers, session)).body['items'], isEmpty);
    });

    test('rejects saving the same account twice', () async {
      await save();
      expect(MockApiHarness.errorCode(await save(nickname: 'Again')), FailureCodes.savedBillerExists);
    });
  });

  group('bill schedules', () {
    Future<MockResponse> schedule(String savedBillerId, {bool autopay = false, String pinHash = 'hash-a'}) => harness.authorized(
      'POST',
      ApiPaths.billSchedules,
      session,
      body: {
        'approval': ?(autopay ? {'method': Approver.pinMethod, 'pinHash': pinHash} : null),
        'autopay': autopay,
        'dayOfMonth': 25,
        'savedBillerId': savedBillerId,
      },
      headers: {ApiHeaders.idempotencyKey: 'mandate-$autopay'},
    );

    test('a reminder never moves money', () async {
      final savedBillerId = (await save()).body['id'] as String;
      expect((await schedule(savedBillerId)).statusCode, 201);
      final startingBalance = await balance();
      harness.now = DateTime.utc(2026, 9, 25, 6);
      session = await harness.login();
      final items = (await harness.authorized('GET', ApiPaths.billSchedules, session)).body['items'] as List<dynamic>;
      expect((items.single as Map<String, dynamic>)['lastStatus'], isNull);
      expect(await balance(), startingBalance);
    });

    test('autopay needs the PIN when it is set up', () async {
      final savedBillerId = (await save()).body['id'] as String;
      expect(MockApiHarness.errorCode(await schedule(savedBillerId, autopay: true, pinHash: 'hash-b')), FailureCodes.pinInvalid);
    });

    test('autopay pays the whole bill once its day arrives, and only once', () async {
      final savedBillerId = (await save()).body['id'] as String;
      final due = await amountDue();
      expect((await schedule(savedBillerId, autopay: true)).statusCode, 201);
      final startingBalance = await balance();
      harness.now = DateTime.utc(2026, 9, 25, 6);
      session = await harness.login();
      final items = (await harness.authorized('GET', ApiPaths.billSchedules, session)).body['items'] as List<dynamic>;
      expect((items.single as Map<String, dynamic>)['lastStatus'], BillsMockModule.paidRun);
      await harness.authorized('GET', ApiPaths.billSchedules, session);
      expect(await balance(), startingBalance - due);
    });

    test('allows one schedule per saved biller', () async {
      final savedBillerId = (await save()).body['id'] as String;
      await schedule(savedBillerId);
      expect(MockApiHarness.errorCode(await schedule(savedBillerId)), FailureCodes.scheduleExists);
    });
  });
}
