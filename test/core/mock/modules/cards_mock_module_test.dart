import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/modules/cards_mock_module.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/utils/card_number.dart';
import 'package:salli/core/utils/path_template.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  Future<Map<String, dynamic>> card() async => ((await harness.authorized('GET', ApiPaths.cards, session)).body['items'] as List<dynamic>).single as Map<String, dynamic>;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  test('issues one card with a few past purchases, never exposing the full number', () async {
    final first = await card();
    expect(first['status'], CardsMockModule.active);
    expect(first.containsKey('number'), isFalse);
    expect(first['spentCents'], CardsMockModule.seedPurchases.fold<int>(0, (sum, purchase) => sum + purchase.amountCents));
    expect((await card())['id'], first['id']);
    final transactions = (await harness.authorized('GET', ApiPaths.cardTransactions.withId(first['id'] as String), session)).body['items'] as List<dynamic>;
    expect(transactions, hasLength(CardsMockModule.seedPurchases.length));
  });

  test('reveals a valid card number only with the PIN', () async {
    final id = (await card())['id'] as String;
    expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.cardReveal.withId(id), session, body: {'approval': harness.unlockApproval(pinHash: 'hash-b')})), FailureCodes.pinInvalid);
    final secrets = (await harness.authorized('POST', ApiPaths.cardReveal.withId(id), session, body: {'approval': harness.unlockApproval(pinHash: 'hash-a')})).body;
    expect(CardNumber.isValid(secrets['number'] as String), isTrue);
    expect((secrets['number'] as String).endsWith((await card())['last4'] as String), isTrue);
  });

  test('a frozen card declines purchases until it is unfrozen', () async {
    final id = (await card())['id'] as String;
    await harness.authorized('PATCH', ApiPaths.card.withId(id), session, body: {'status': CardsMockModule.frozen});
    expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.cardTestPurchase.withId(id), session)), FailureCodes.cardFrozen);
    await harness.authorized('PATCH', ApiPaths.card.withId(id), session, body: {'status': CardsMockModule.active});
    expect((await harness.authorized('POST', ApiPaths.cardTestPurchase.withId(id), session)).statusCode, 201);
  });

  test('the spending limit stops a purchase that would go over it', () async {
    final id = (await card())['id'] as String;
    await harness.authorized('PATCH', ApiPaths.card.withId(id), session, body: {'spendLimitCents': CardsMockModule.minLimitCents});
    expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.cardTestPurchase.withId(id), session)), FailureCodes.cardLimitExceeded);
  });

  test('rejects a spending limit out of range', () async {
    final id = (await card())['id'] as String;
    expect(MockApiHarness.errorCode(await harness.authorized('PATCH', ApiPaths.card.withId(id), session, body: {'spendLimitCents': 1})), FailureCodes.invalidLimit);
  });
}
