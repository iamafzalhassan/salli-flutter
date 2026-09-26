import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_collections.dart';
import 'package:salli/core/mock/mock_notifier.dart';
import 'package:salli/core/mock/modules/auth_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';
import 'package:salli/core/utils/path_template.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const friendPhone = '+94719998877';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  Future<Map<String, dynamic>> list() async => (await harness.authorized('GET', ApiPaths.notifications, session)).body;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  test('greets a new member with one unread welcome', () async {
    final body = await list();
    expect((body['items'] as List<dynamic>).map((item) => (item as Map<String, dynamic>)['kind']), [MockNotifier.welcome]);
    expect(body['unreadCount'], 1);
    expect((await harness.authorized('GET', ApiPaths.unreadNotifications, session)).body['unreadCount'], 1);
  });

  test('tells the recipient of a transfer who paid and how much', () async {
    final friend = await harness.register(phone: friendPhone);
    final friendId = (friend['user'] as Map<String, dynamic>)['id'] as String;
    harness.now = harness.now.add(AuthMockModule.resendDelay);
    session = await harness.login();
    final response = await harness.authorized(
      'POST',
      ApiPaths.transfers,
      session,
      body: {
        'amountCents': 50000,
        'approval': {'method': Approver.pinMethod, 'pinHash': 'hash-a'},
        'recipientPhone': friendPhone,
      },
      headers: {ApiHeaders.idempotencyKey: 'transfer-1'},
    );
    expect(response.statusCode, 201);
    final received = harness.store.all(MockCollections.notifications).singleWhere((item) => item['userId'] == friendId && item['kind'] == MockNotifier.moneyReceived);
    expect((received['params'] as Map<String, dynamic>)['amountCents'], 50000);
    expect((received['params'] as Map<String, dynamic>)['transactionId'], response.body['id']);
  });

  test('marks one as read, then all of them', () async {
    final first = ((await list())['items'] as List<dynamic>).first as Map<String, dynamic>;
    expect((await harness.authorized('POST', ApiPaths.notificationRead.withId(first['id'] as String), session)).statusCode, 204);
    expect((await list())['unreadCount'], 0);
    final userId = (session['user'] as Map<String, dynamic>)['id'] as String;
    await MockNotifier(harness.store, clock: () => harness.now).notify(userId, MockNotifier.kycVerified);
    await MockNotifier(harness.store, clock: () => harness.now).notify(userId, MockNotifier.requestReceived, params: {'amountCents': 1000, 'name': 'Nimal'});
    expect((await list())['unreadCount'], 2);
    expect((await harness.authorized('POST', ApiPaths.notificationsReadAll, session)).statusCode, 204);
    expect((await list())['unreadCount'], 0);
  });

  test("cannot read someone else's notification", () async {
    final first = ((await list())['items'] as List<dynamic>).first as Map<String, dynamic>;
    final friend = await harness.register(phone: friendPhone);
    expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.notificationRead.withId(first['id'] as String), friend)), FailureCodes.notFound);
  });
}
