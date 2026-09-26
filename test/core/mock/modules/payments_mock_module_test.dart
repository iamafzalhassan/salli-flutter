import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_collections.dart';
import 'package:salli/core/mock/mock_ledger.dart';
import 'package:salli/core/mock/mock_limits.dart';
import 'package:salli/core/mock/mock_pin_verifier.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/mock_wallet_seeder.dart';
import 'package:salli/core/mock/modules/payments_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const fathima = '+94704445566';
  const unknown = '+94777000000';

  final harness = MockApiHarness();
  final seededBalance = MockWalletSeeder.seed.fold<int>(0, (sum, entry) => sum + entry.$5);

  late Map<String, dynamic> session;

  Future<MockResponse> transfer(int amountCents, {String? key = 'key-1', String pinHash = 'hash-a', String recipient = fathima}) => harness.authorized(
    'POST',
    ApiPaths.transfers,
    session,
    body: {
      'amountCents': amountCents,
      'approval': {'method': Approver.pinMethod, 'pinHash': pinHash},
      'note': 'Lunch',
      'recipientPhone': recipient,
    },
    headers: {ApiHeaders.idempotencyKey: ?key},
  );

  Future<int> balance() async => (await harness.authorized('GET', ApiPaths.wallet, session)).body['balanceCents'] as int;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  group('GET /v1/payees/lookup', () {
    Future<MockResponse> lookup(String phone) => harness.authorized('GET', ApiPaths.payeeLookup, session, query: {'phone': phone});

    test('finds a person in the directory', () async {
      final response = await lookup(fathima);
      expect(response.statusCode, 200);
      expect(response.body['name'], PaymentsMockModule.directory[fathima]);
    });

    test('rejects an unknown number', () async => expect(MockApiHarness.errorCode(await lookup(unknown)), FailureCodes.payeeNotFound));

    test('rejects your own number', () async => expect(MockApiHarness.errorCode(await lookup(MockApiHarness.phone)), FailureCodes.cannotPaySelf));

    test('rejects a malformed number', () async => expect(MockApiHarness.errorCode(await lookup('0771234567')), FailureCodes.invalidPhone));
  });

  group('GET /v1/payees/recent', () {
    test('lists people from past transfers, newest first', () async {
      await transfer(10000);
      final items = (await harness.authorized('GET', ApiPaths.recentPayees, session)).body['items'] as List<dynamic>;
      final phones = [for (final item in items.cast<Map<String, dynamic>>()) item['phone']];
      expect(phones, [fathima, '+94771112233', '+94712223344']);
    });
  });

  group('POST /v1/transfers', () {
    test('moves money through balanced ledger entries', () async {
      final response = await transfer(125050);
      expect(response.statusCode, 201);
      expect(response.body['reference'], matches(RegExp('^${MockLedger.referencePrefix}\\d{${MockLedger.referenceDigits}}\$')));
      expect(response.body['recipientName'], PaymentsMockModule.directory[fathima]);
      expect(await balance(), seededBalance - 125050);
      final entries = harness.store.all(MockCollections.ledgerEntries);
      expect(entries.fold<int>(0, (sum, entry) => sum + (entry['amountCents'] as int)), 0);
    });

    test('replaying the same idempotency key never moves money twice', () async {
      final first = await transfer(50000);
      final second = await transfer(50000);
      expect(second.body['id'], first.body['id']);
      expect(await balance(), seededBalance - 50000);
    });

    test('requires an idempotency key', () async => expect(MockApiHarness.errorCode(await transfer(50000, key: null)), FailureCodes.idempotencyKeyRequired));

    test('rejects a wrong PIN without moving money', () async {
      expect(MockApiHarness.errorCode(await transfer(50000, pinHash: 'hash-b')), FailureCodes.pinInvalid);
      expect(await balance(), seededBalance);
    });

    test('locks the PIN after five wrong attempts, shared with sign-in', () async {
      for (var attempt = 1; attempt < MockPinVerifier.maxAttempts; attempt++) {
        expect(MockApiHarness.errorCode(await transfer(50000, key: 'key-$attempt', pinHash: 'hash-b')), FailureCodes.pinInvalid);
      }
      expect(MockApiHarness.errorCode(await transfer(50000, key: 'key-last', pinHash: 'hash-b')), FailureCodes.pinLocked);
      expect(MockApiHarness.errorCode(await transfer(50000, key: 'key-after')), FailureCodes.pinLocked);
    });

    test('rejects more than the wallet holds', () async => expect(MockApiHarness.errorCode(await transfer(seededBalance + 1)), FailureCodes.insufficientFunds));

    test('rejects more than the single payment limit', () async => expect(MockApiHarness.errorCode(await transfer(MockLimits.tiers[MockLimits.basicTier]!.perPaymentCents + 1)), FailureCodes.limitExceeded));

    test('counts every payment in the last 24 hours toward the daily limit', () async {
      final perPayment = MockLimits.tiers[MockLimits.basicTier]!.perPaymentCents;
      await harness.fund(session, perPayment * 4);
      expect((await transfer(perPayment, key: 'key-a')).statusCode, 201);
      expect(MockApiHarness.errorCode(await transfer(perPayment, key: 'key-b')), FailureCodes.dailyLimitExceeded);
    });

    test('rejects a zero amount', () async => expect(MockApiHarness.errorCode(await transfer(0)), FailureCodes.invalidAmount));

    test('rejects paying yourself', () async => expect(MockApiHarness.errorCode(await transfer(100, recipient: MockApiHarness.phone)), FailureCodes.cannotPaySelf));

    test('rejects an unknown recipient', () async => expect(MockApiHarness.errorCode(await transfer(100, recipient: unknown)), FailureCodes.payeeNotFound));
  });
}
