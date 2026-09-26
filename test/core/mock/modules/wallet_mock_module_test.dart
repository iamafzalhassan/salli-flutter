import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_authenticator.dart';
import 'package:salli/core/mock/mock_collections.dart';
import 'package:salli/core/mock/mock_request.dart';
import 'package:salli/core/mock/mock_wallet_seeder.dart';
import 'package:salli/core/mock/modules/wallet_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/utils/path_template.dart';

import '../../../helpers/mock_api_harness.dart';
import '../../../helpers/test_device_key.dart';

void main() {
  final harness = MockApiHarness();
  final seededBalance = MockWalletSeeder.seed.fold<int>(0, (sum, entry) => sum + entry.$5);

  setUp(harness.setUp);

  tearDown(harness.tearDown);

  group('GET /v1/wallet', () {
    test('seeds a new wallet whose balance is the sum of its ledger', () async {
      final session = await harness.register();
      final response = await harness.authorized('GET', ApiPaths.wallet, session);
      expect(response.statusCode, 200);
      expect(response.body['balanceCents'], seededBalance);
      expect(response.body['currency'], WalletMockModule.currency);
    });

    test('keeps the ledger balanced: every debit has a matching credit', () async {
      final session = await harness.register();
      await harness.authorized('GET', ApiPaths.wallet, session);
      final entries = harness.store.all(MockCollections.ledgerEntries);
      expect(entries, hasLength(MockWalletSeeder.seed.length * 2));
      expect(entries.fold<int>(0, (sum, entry) => sum + (entry['amountCents'] as int)), 0);
    });

    test('seeds once even when the wallet and the transactions are requested together', () async {
      final session = await harness.register();
      await Future.wait([harness.authorized('GET', ApiPaths.wallet, session), harness.authorized('GET', ApiPaths.transactions, session)]);
      expect(harness.store.all(MockCollections.ledgerTransactions), hasLength(MockWalletSeeder.seed.length));
    });

    test('seeds only once', () async {
      final session = await harness.register();
      await harness.authorized('GET', ApiPaths.wallet, session);
      final response = await harness.authorized('GET', ApiPaths.wallet, session);
      expect(response.body['balanceCents'], seededBalance);
    });
  });

  group('GET /v1/transactions', () {
    test('returns the newest first and pages with a cursor', () async {
      final session = await harness.register();
      final first = await harness.authorized('GET', ApiPaths.transactions, session, query: {'limit': 3});
      final firstItems = first.body['items'] as List<dynamic>;
      expect(firstItems, hasLength(3));
      expect((firstItems.first as Map<String, dynamic>)['counterpartyName'], 'Kavindi Silva');
      expect((firstItems.first as Map<String, dynamic>)['type'], WalletMockModule.transferOut);
      final rest = await harness.authorized('GET', ApiPaths.transactions, session, query: {'cursor': first.body['nextCursor'], 'limit': 10});
      expect(rest.body['items'], hasLength(MockWalletSeeder.seed.length - 3));
      expect(rest.body['nextCursor'], isNull);
    });

    test('marks money received from a person as transfer_in', () async {
      final session = await harness.register();
      final items = (await harness.authorized('GET', ApiPaths.transactions, session)).body['items'] as List<dynamic>;
      final received = items.cast<Map<String, dynamic>>().firstWhere((item) => item['counterpartyName'] == 'Nimal Perera');
      expect(received['type'], WalletMockModule.transferIn);
      expect(received['amountCents'], isPositive);
    });

    test('rejects an unknown cursor', () async {
      final session = await harness.register();
      final response = await harness.authorized('GET', ApiPaths.transactions, session, query: {'cursor': 'missing'});
      expect(MockApiHarness.errorCode(response), FailureCodes.invalidRequest);
    });
  });

  group('GET /v1/transactions filters', () {
    Future<List<Map<String, dynamic>>> items(Map<String, dynamic> session, Map<String, dynamic> query) async =>
        ((await harness.authorized('GET', ApiPaths.transactions, session, query: query)).body['items'] as List<dynamic>).cast<Map<String, dynamic>>();

    test('searches the counterparty name without regard to case', () async {
      final session = await harness.register();
      expect((await items(session, {'q': 'pick'})).map((item) => item['counterpartyName']), ['PickMe']);
    });

    test('filters by a list of types', () async {
      final session = await harness.register();
      final matches = await items(session, {'type': 'merchant,reload'});
      expect(matches, hasLength(3));
      expect(matches.map((item) => item['type']).toSet(), {'merchant', 'reload'});
    });

    test('filters by the size of the amount either way', () async {
      final session = await harness.register();
      expect((await items(session, {'minCents': 400000})).map((item) => item['counterpartyName']).toSet(), {'Keells Super', 'Nimal Perera', 'Salli'});
      expect((await items(session, {'maxCents': 60000})).map((item) => item['counterpartyName']), ['Dialog']);
    });

    test('filters by date, including from and excluding to', () async {
      final session = await harness.register();
      final from = harness.now.subtract(const Duration(days: 1)).toIso8601String();
      expect((await items(session, {'from': from})).map((item) => item['counterpartyName']), ['Kavindi Silva', 'PickMe']);
      expect(await items(session, {'from': from, 'to': harness.now.subtract(const Duration(hours: 1)).toIso8601String()}), hasLength(1));
    });
  });

  group('GET /v1/transactions/:id', () {
    Future<Map<String, dynamic>> latest(Map<String, dynamic> session) async => ((await harness.authorized('GET', ApiPaths.transactions, session, query: {'limit': 1})).body['items'] as List<dynamic>).first as Map<String, dynamic>;

    test('returns the timeline and what it takes to pay again', () async {
      final session = await harness.register();
      final transaction = await latest(session);
      final response = await harness.authorized('GET', ApiPaths.transaction.withId(transaction['id'] as String), session);
      expect(response.statusCode, 200);
      expect(response.body['counterpartyName'], 'Kavindi Silva');
      expect((response.body['timeline'] as List<dynamic>).map((step) => (step as Map<String, dynamic>)['status']), ['initiated', 'completed']);
      expect(response.body['repeat'], {'kind': 'transfer', 'name': 'Kavindi Silva', 'phone': '+94771112233'});
      expect(response.body['dispute'], isNull);
    });

    test('offers nothing to repeat for money received', () async {
      final session = await harness.register();
      final all = (await harness.authorized('GET', ApiPaths.transactions, session)).body['items'] as List<dynamic>;
      final received = all.cast<Map<String, dynamic>>().firstWhere((item) => item['type'] == WalletMockModule.transferIn);
      expect((await harness.authorized('GET', ApiPaths.transaction.withId(received['id'] as String), session)).body['repeat'], isNull);
    });

    test('hides a transaction that belongs to someone else', () async {
      final owner = await harness.register();
      final transaction = await latest(owner);
      final other = await harness.register(phone: '+94719998877');
      expect(MockApiHarness.errorCode(await harness.authorized('GET', ApiPaths.transaction.withId(transaction['id'] as String), other)), FailureCodes.notFound);
    });
  });

  group('POST /v1/transactions/:id/disputes', () {
    Future<String> latestPath(Map<String, dynamic> session) async {
      final items = (await harness.authorized('GET', ApiPaths.transactions, session, query: {'limit': 1})).body['items'] as List<dynamic>;
      return ApiPaths.transactionDisputes.withId((items.first as Map<String, dynamic>)['id'] as String);
    }

    test('opens one case per transaction', () async {
      final session = await harness.register();
      final path = await latestPath(session);
      final created = await harness.authorized('POST', path, session, body: {'details': 'Charged twice', 'reason': 'duplicate'});
      expect(created.statusCode, 201);
      expect(created.body['status'], 'open');
      expect(created.body['reference'], startsWith('DSP'));
      expect(MockApiHarness.errorCode(await harness.authorized('POST', path, session, body: {'reason': 'other'})), FailureCodes.disputeExists);
    });

    test('rejects an unknown reason and over-long details', () async {
      final session = await harness.register();
      final path = await latestPath(session);
      expect(MockApiHarness.errorField(await harness.authorized('POST', path, session, body: {'reason': 'bored'})), 'reason');
      expect(MockApiHarness.errorField(await harness.authorized('POST', path, session, body: {'details': 'x' * (WalletMockModule.maxDetailsLength + 1), 'reason': 'other'})), 'details');
    });
  });

  group('GET /v1/insights', () {
    test('sums spending by category and money in for the month', () async {
      final session = await harness.register();
      final response = await harness.authorized('GET', ApiPaths.insights, session, query: {'month': '2026-09'});
      expect(response.statusCode, 200);
      expect(response.body['spendingCents'], 428550 + 50000 + 364000 + 82000 + 150000);
      expect(response.body['incomeCents'], 2500000 + 750000);
      expect(response.body['previousSpendingCents'], 0);
      expect((response.body['categories'] as List<dynamic>).map((category) => (category as Map<String, dynamic>)['category']), ['grocery', 'bills', 'transfers', 'transport', 'reload']);
    });

    test('rejects a malformed month', () async {
      final session = await harness.register();
      expect(MockApiHarness.errorField(await harness.authorized('GET', ApiPaths.insights, session, query: {'month': 'September'})), 'month');
    });
  });

  group('request authentication', () {
    test('rejects a request without an access token', () async {
      expect(MockApiHarness.errorCode(await harness.send('GET', ApiPaths.wallet)), FailureCodes.unauthorized);
    });

    test('rejects a valid token without a device signature', () async {
      final session = await harness.register();
      expect(MockApiHarness.errorCode(await harness.send('GET', ApiPaths.wallet, accessToken: session['accessToken'] as String)), FailureCodes.signatureInvalid);
    });

    test('rejects a signature from another key', () async {
      final session = await harness.register();
      final response = await harness.send('GET', ApiPaths.wallet, accessToken: session['accessToken'] as String, isSigned: true, signingKey: TestDeviceKey.generate(99));
      expect(MockApiHarness.errorCode(response), FailureCodes.signatureInvalid);
    });

    test('rejects a replayed nonce', () async {
      final session = await harness.register();
      final token = session['accessToken'] as String;
      expect((await harness.send('GET', ApiPaths.wallet, accessToken: token, isSigned: true, nonce: 'nonce-1')).statusCode, 200);
      expect(MockApiHarness.errorCode(await harness.send('GET', ApiPaths.wallet, accessToken: token, isSigned: true, nonce: 'nonce-1')), FailureCodes.replayedRequest);
    });

    test('rejects a request signed outside the allowed clock skew', () async {
      final session = await harness.register();
      final response = await harness.send('GET', ApiPaths.wallet, accessToken: session['accessToken'] as String, isSigned: true, signingSkew: -(MockAuthenticator.maxClockSkew * 2));
      expect(MockApiHarness.errorCode(response), FailureCodes.signatureInvalid);
    });

    test('rejects a signature over different query parameters', () async {
      final session = await harness.register();
      final headers = {
        ApiHeaders.authorization: 'Bearer ${session['accessToken']}',
        ...harness.deviceKey.signedHeaders(deviceId: MockApiHarness.deviceId, method: 'GET', nonce: 'nonce-2', path: ApiPaths.transactions, query: {'limit': 1}, signedAt: harness.now),
      };
      final response = await harness.server.handle(MockRequest(body: const {}, headers: headers, method: 'GET', path: ApiPaths.transactions, query: const {'limit': 2}));
      expect(MockApiHarness.errorCode(response), FailureCodes.signatureInvalid);
    });
  });
}
