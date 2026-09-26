import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/modules/requests_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/utils/path_template.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const fathima = '+94704445566';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  Future<List<Map<String, dynamic>>> requests() async => ((await harness.authorized('GET', ApiPaths.moneyRequests, session)).body['items'] as List<dynamic>).cast<Map<String, dynamic>>();

  Future<MockResponse> create({int amountCents = 50000, String phone = fathima}) => harness.authorized('POST', ApiPaths.moneyRequests, session, body: {'amountCents': amountCents, 'note': 'Lunch', 'phone': phone});

  Future<int> balance() async => (await harness.authorized('GET', ApiPaths.wallet, session)).body['balanceCents'] as int;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  test('every new account has one incoming request to try paying', () async {
    final incoming = (await requests()).where((request) => request['direction'] == RequestsMockModule.incoming).toList();
    expect(incoming.single['amountCents'], RequestsMockModule.seedRequest.amountCents);
    expect(incoming.single['status'], RequestsMockModule.pending);
  });

  test('paying a request through a transfer settles it', () async {
    final incoming = (await requests()).singleWhere((request) => request['direction'] == RequestsMockModule.incoming);
    final response = await harness.authorized(
      'POST',
      ApiPaths.transfers,
      session,
      body: {
        'amountCents': incoming['amountCents'],
        'approval': {'method': Approver.pinMethod, 'pinHash': 'hash-a'},
        'recipientPhone': incoming['counterpartyPhone'],
        'requestId': incoming['id'],
      },
      headers: {ApiHeaders.idempotencyKey: 'key-1'},
    );
    expect(response.statusCode, 201);
    expect((await requests()).singleWhere((request) => request['id'] == incoming['id'])['status'], RequestsMockModule.paid);
  });

  test('a request can only be paid for its exact amount', () async {
    final incoming = (await requests()).singleWhere((request) => request['direction'] == RequestsMockModule.incoming);
    final response = await harness.authorized(
      'POST',
      ApiPaths.transfers,
      session,
      body: {
        'amountCents': (incoming['amountCents'] as int) + 1,
        'approval': {'method': Approver.pinMethod, 'pinHash': 'hash-a'},
        'recipientPhone': incoming['counterpartyPhone'],
        'requestId': incoming['id'],
      },
      headers: {ApiHeaders.idempotencyKey: 'key-1'},
    );
    expect(MockApiHarness.errorCode(response), FailureCodes.amountMismatch);
  });

  test('declining an incoming request closes it', () async {
    final incoming = (await requests()).singleWhere((request) => request['direction'] == RequestsMockModule.incoming);
    expect((await harness.authorized('POST', ApiPaths.moneyRequestDecline.withId(incoming['id'] as String), session)).body['status'], RequestsMockModule.declined);
    expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.moneyRequestDecline.withId(incoming['id'] as String), session)), FailureCodes.requestNotPending);
  });

  test('rejects requesting money from yourself', () async => expect(MockApiHarness.errorCode(await create(phone: MockApiHarness.phone)), FailureCodes.cannotRequestSelf));

  test('a contact from the directory pays back a couple of minutes later', () async {
    final id = (await create()).body['id'] as String;
    final startingBalance = await balance();
    harness.now = harness.now.add(RequestsMockModule.directoryReplyDelay);
    final request = (await requests()).singleWhere((request) => request['id'] == id);
    expect(request['status'], RequestsMockModule.paid);
    expect(await balance(), startingBalance + 50000);
  });

  test('reminds once a day at most', () async {
    final id = (await create()).body['id'] as String;
    expect((await harness.authorized('POST', ApiPaths.moneyRequestRemind.withId(id), session)).statusCode, 200);
    expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.moneyRequestRemind.withId(id), session)), FailureCodes.remindTooSoon);
  });

  test('cancelling stops an outgoing request', () async {
    final id = (await create()).body['id'] as String;
    expect((await harness.authorized('POST', ApiPaths.moneyRequestCancel.withId(id), session)).body['status'], RequestsMockModule.cancelled);
  });

  group('splits', () {
    Future<MockResponse> split(int amountCents, List<String> phones, {bool includeSelf = true}) =>
        harness.authorized('POST', ApiPaths.splits, session, body: {'amountCents': amountCents, 'includeSelf': includeSelf, 'note': 'Dinner', 'phones': phones});

    test('shares always add up to the bill, with the odd cent on the first share', () async {
      final response = await split(1000, [fathima, '+94712223344']);
      final shares = (response.body['shares'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect([for (final share in shares) share['amountCents']], [334, 333, 333]);
      expect(shares.first['isSelf'], isTrue);
    });

    test('requests each person their share', () async {
      await split(90000, [fathima, '+94712223344'], includeSelf: false);
      final outgoing = (await requests()).where((request) => request['direction'] == RequestsMockModule.outgoing).toList();
      expect([for (final request in outgoing) request['amountCents']], [45000, 45000]);
      expect(outgoing.every((request) => request['splitId'] != null), isTrue);
    });

    test('rejects the same person twice', () async => expect(MockApiHarness.errorCode(await split(1000, [fathima, fathima])), FailureCodes.invalidRequest));
  });
}
