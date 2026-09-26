import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/modules/funding_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/utils/path_template.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const visa = '4111111111111111';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  Future<Map<String, dynamic>> linkBank() async {
    final challenge = (await harness.authorized('POST', ApiPaths.fundingBank, session, body: {'accountNumber': '0012345678', 'bankCode': '7010'})).body;
    return (await harness.authorized('POST', ApiPaths.fundingBankVerify, session, body: {'challengeId': challenge['challengeId'], 'code': harness.deliveredCode})).body;
  }

  Future<MockResponse> addCard({String number = visa, int expiryYear = 2030, String cvv = '123'}) =>
      harness.authorized('POST', ApiPaths.fundingCard, session, body: {'cvv': cvv, 'expiryMonth': 12, 'expiryYear': expiryYear, 'number': number});

  Future<MockResponse> move(String path, String sourceId, int amountCents, {String key = 'key-1'}) => harness.authorized(
    'POST',
    path,
    session,
    body: {
      'amountCents': amountCents,
      'approval': {'method': Approver.pinMethod, 'pinHash': 'hash-a'},
      'sourceId': sourceId,
    },
    headers: {ApiHeaders.idempotencyKey: key},
  );

  Future<int> balance() async => (await harness.authorized('GET', ApiPaths.wallet, session)).body['balanceCents'] as int;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  test('links a bank account once the code sent by SMS is entered', () async {
    final source = await linkBank();
    expect(source['type'], FundingMockModule.bankType);
    expect(source['last4'], '5678');
    expect((await harness.authorized('GET', ApiPaths.fundingSources, session)).body['items'], hasLength(1));
  });

  test('rejects a wrong linking code', () async {
    final challenge = (await harness.authorized('POST', ApiPaths.fundingBank, session, body: {'accountNumber': '0012345678', 'bankCode': '7010'})).body;
    final wrong = harness.deliveredCode == '000000' ? '111111' : '000000';
    expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.fundingBankVerify, session, body: {'challengeId': challenge['challengeId'], 'code': wrong})), FailureCodes.otpInvalid);
  });

  test('keeps only the brand and last four digits of a card', () async {
    final response = await addCard();
    expect(response.statusCode, 201);
    expect(response.body, {'bankCode': null, 'brand': 'Visa', 'id': response.body['id'], 'label': 'Visa', 'last4': '1111', 'type': FundingMockModule.cardType});
  });

  test('rejects a card number that fails the checksum', () async => expect(MockApiHarness.errorCode(await addCard(number: '4111111111111112')), FailureCodes.invalidCardNumber));

  test('rejects an expired card', () async => expect(MockApiHarness.errorCode(await addCard(expiryYear: 2020)), FailureCodes.cardExpired));

  test('a card the bank declines is not added', () async => expect(MockApiHarness.errorCode(await addCard(number: '4000000000000002')), FailureCodes.cardDeclined));

  test('a top-up credits the wallet', () async {
    final sourceId = (await addCard()).body['id'] as String;
    final startingBalance = await balance();
    expect((await move(ApiPaths.topUps, sourceId, 500000)).statusCode, 201);
    expect(await balance(), startingBalance + 500000);
  });

  test('a top-up must be between the minimum and maximum', () async {
    final sourceId = (await addCard()).body['id'] as String;
    expect(MockApiHarness.errorCode(await move(ApiPaths.topUps, sourceId, FundingMockModule.minTopUpCents - 1)), FailureCodes.topUpOutOfRange);
  });

  test('withdraws to a linked bank account but not to a card', () async {
    final bankId = (await linkBank())['id'] as String;
    final cardId = (await addCard()).body['id'] as String;
    final startingBalance = await balance();
    expect((await move(ApiPaths.withdrawals, bankId, 100000)).statusCode, 201);
    expect(await balance(), startingBalance - 100000);
    expect(MockApiHarness.errorCode(await move(ApiPaths.withdrawals, cardId, 100000, key: 'key-2')), FailureCodes.invalidRequest);
  });

  test('removes a source', () async {
    final sourceId = (await addCard()).body['id'] as String;
    expect((await harness.authorized('DELETE', ApiPaths.fundingSource.withId(sourceId), session)).statusCode, 204);
    expect(MockApiHarness.errorCode(await move(ApiPaths.topUps, sourceId, 500000)), FailureCodes.sourceNotFound);
  });
}
