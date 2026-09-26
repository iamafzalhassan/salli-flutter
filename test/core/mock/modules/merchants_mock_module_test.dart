import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_collections.dart';
import 'package:salli/core/mock/mock_offers.dart';
import 'package:salli/core/mock/mock_qr_codes.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/mock_wallet_seeder.dart';
import 'package:salli/core/mock/modules/merchants_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/utils/lanka_qr.dart';
import 'package:salli/core/utils/money.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const keellsId = 'LKQR00000001';

  final harness = MockApiHarness();
  final seededBalance = MockWalletSeeder.seed.fold<int>(0, (sum, entry) => sum + entry.$5);
  final keells = const LankaQr(accountId: keellsId, categoryCode: '5411', city: 'Colombo 07', guid: LankaQr.merchantGuid, isDynamic: false, name: 'Keells Super').encode();
  final pickMe = const LankaQr(accountId: 'LKQR00000003', amount: Money(82000), categoryCode: '4121', city: 'Colombo 03', guid: LankaQr.merchantGuid, isDynamic: true, name: 'PickMe').encode();

  late Map<String, dynamic> session;

  Future<MockResponse> lookup(String qr) => harness.authorized('POST', ApiPaths.merchantLookup, session, body: {'qr': qr});

  Future<MockResponse> pay(String qr, int amountCents, {String? key = 'key-1', String pinHash = 'hash-a'}) => harness.authorized(
    'POST',
    ApiPaths.merchantPayments,
    session,
    body: {
      'amountCents': amountCents,
      'approval': {'method': Approver.pinMethod, 'pinHash': pinHash},
      'qr': qr,
    },
    headers: {ApiHeaders.idempotencyKey: ?key},
  );

  Future<int> balance() async => (await harness.authorized('GET', ApiPaths.wallet, session)).body['balanceCents'] as int;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  group('POST /v1/merchants/lookup', () {
    test('names a registered merchant from the directory, not from the sticker', () async {
      final response = await lookup(const LankaQr(accountId: keellsId, categoryCode: '5411', city: 'Anywhere', guid: LankaQr.merchantGuid, isDynamic: false, name: 'Fake Name').encode());
      expect(response.statusCode, 200);
      expect(response.body['merchant'], {'category': 'grocery', 'city': 'Colombo 07', 'id': keellsId, 'name': 'Keells Super'});
      expect(response.body.containsKey('amountCents'), isFalse);
    });

    test('returns the fixed amount of a dynamic code', () async => expect((await lookup(pickMe)).body['amountCents'], 82000));

    test('rejects a merchant that is not registered', () async {
      final unregistered = MockQrCodes.all.singleWhere((code) => LankaQr.parse(code).accountId == MockQrCodes.unregisteredMerchantId);
      expect(MockApiHarness.errorCode(await lookup(unregistered)), FailureCodes.merchantNotFound);
    });

    test('rejects a personal code', () async => expect(MockApiHarness.errorCode(await lookup(const LankaQr.personal(name: 'Nimal', phone: '+94712223344').encode())), FailureCodes.merchantNotFound));

    test('rejects a tampered code', () async => expect(MockApiHarness.errorCode(await lookup(keells.replaceFirst('Keells', 'Kee11s'))), FailureCodes.invalidQr));

    test('every demo code except the unregistered one resolves', () async {
      for (final code in MockQrCodes.all.where((code) => !LankaQr.parse(code).isPersonal && LankaQr.parse(code).accountId != MockQrCodes.unregisteredMerchantId)) {
        expect((await lookup(code)).statusCode, 200);
      }
    });
  });

  group('POST /v1/merchant-payments', () {
    test('pays any amount to a static code through balanced ledger entries', () async {
      final response = await pay(keells, 428550);
      expect(response.statusCode, 201);
      expect((response.body['merchant'] as Map<String, dynamic>)['name'], 'Keells Super');
      final offer = MockOffers.forMerchant(keellsId)!;
      expect(await balance(), seededBalance - 428550 + min(428550 * offer.cashbackPercent ~/ 100, offer.maxCashbackCents));
      final entries = harness.store.all(MockCollections.ledgerEntries);
      expect(entries.fold<int>(0, (sum, entry) => sum + (entry['amountCents'] as int)), 0);
      expect(entries.where((entry) => entry['account'] == MerchantsMockModule.merchantAccount(keellsId)).single['amountCents'], 428550);
    });

    test('shows up in activity as a merchant payment', () async {
      await pay(keells, 10000);
      final latest = ((await harness.authorized('GET', ApiPaths.transactions, session)).body['items'] as List<dynamic>).first as Map<String, dynamic>;
      expect(latest['type'], MerchantsMockModule.transactionType);
      expect(latest['counterpartyName'], 'Keells Super');
      expect(latest['amountCents'], -10000);
    });

    test('pays the exact amount of a dynamic code', () async => expect((await pay(pickMe, 82000)).statusCode, 201));

    test('rejects a different amount for a dynamic code without moving money', () async {
      expect(MockApiHarness.errorCode(await pay(pickMe, 82001)), FailureCodes.amountMismatch);
      expect(await balance(), seededBalance);
    });

    test('replaying the same idempotency key never moves money twice', () async {
      final first = await pay(keells, 50000);
      final second = await pay(keells, 50000);
      expect(second.body['id'], first.body['id']);
      expect(await balance(), seededBalance - 50000);
    });

    test('requires an idempotency key', () async => expect(MockApiHarness.errorCode(await pay(keells, 50000, key: null)), FailureCodes.idempotencyKeyRequired));

    test('rejects a wrong PIN without moving money', () async {
      expect(MockApiHarness.errorCode(await pay(keells, 50000, pinHash: 'hash-b')), FailureCodes.pinInvalid);
      expect(await balance(), seededBalance);
    });

    test('rejects more than the wallet holds', () async => expect(MockApiHarness.errorCode(await pay(keells, seededBalance + 1)), FailureCodes.insufficientFunds));

    test('rejects a zero amount', () async => expect(MockApiHarness.errorCode(await pay(keells, 0)), FailureCodes.invalidAmount));

    test('rejects a code for another currency', () async {
      final foreign = keells.replaceFirst('5303144', '5303840');
      final data = foreign.substring(0, foreign.length - 4);
      final repaired = '$data${LankaQr.crc16(utf8.encode(data)).toRadixString(16).toUpperCase().padLeft(4, '0')}';
      expect(MockApiHarness.errorCode(await pay(repaired, 1000)), FailureCodes.unsupportedCurrency);
    });
  });
}
