import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/modules/reload_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const dialogNumber = '+94771234567';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  Future<MockResponse> reload(int amountCents, {String phone = dialogNumber, String? planId, String key = 'key-1'}) => harness.authorized(
    'POST',
    ApiPaths.reloads,
    session,
    body: {
      'amountCents': amountCents,
      'approval': {'method': Approver.pinMethod, 'pinHash': 'hash-a'},
      'phone': phone,
      'planId': ?planId,
    },
    headers: {ApiHeaders.idempotencyKey: key},
  );

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  test('lists the amounts and the plans of one network', () async {
    final body = (await harness.authorized('GET', ApiPaths.reloadPlans, session, query: {'operator': 'dialog'})).body;
    expect(body['amounts'], ReloadMockModule.amounts);
    expect(body['items'], hasLength(ReloadMockModule.plans['dialog']!.length));
  });

  test('rejects an unknown network', () async => expect(MockApiHarness.errorCode(await harness.authorized('GET', ApiPaths.reloadPlans, session, query: {'operator': 'nope'})), FailureCodes.invalidRequest));

  test('reloads any amount in range and names the network', () async {
    final response = await reload(20000);
    expect(response.statusCode, 201);
    expect(response.body['operator'], 'dialog');
  });

  test('rejects an amount outside the reload range', () async {
    expect(MockApiHarness.errorCode(await reload(ReloadMockModule.minAmountCents - 1)), FailureCodes.reloadAmountOutOfRange);
    expect(MockApiHarness.errorCode(await reload(ReloadMockModule.maxAmountCents + 1, key: 'key-2')), FailureCodes.reloadAmountOutOfRange);
  });

  test('buys a plan at exactly its price', () async {
    final plan = ReloadMockModule.plans['dialog']!.first;
    expect((await reload(plan.amountCents, planId: plan.id)).body['planName'], plan.name);
    expect(MockApiHarness.errorCode(await reload(plan.amountCents + 1, key: 'key-2', planId: plan.id)), FailureCodes.amountMismatch);
  });

  test('rejects a plan from another network', () async => expect(MockApiHarness.errorCode(await reload(30000, planId: ReloadMockModule.plans['airtel']!.first.id)), FailureCodes.planNotFound));

  test('remembers recently reloaded numbers', () async {
    await reload(20000);
    await reload(10000, key: 'key-2', phone: '+94711234567');
    final items = (await harness.authorized('GET', ApiPaths.recentReloads, session)).body['items'] as List<dynamic>;
    expect([for (final item in items.cast<Map<String, dynamic>>()) item['phone']], unorderedEquals(['+94711234567', dialogNumber]));
  });
}
