import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_collections.dart';
import 'package:salli/core/mock/mock_risk.dart';
import 'package:salli/core/mock/mock_security_log.dart';
import 'package:salli/core/mock/modules/auth_mock_module.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approver.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const fathima = '+94704445566';
  const nic = '199512301234';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  String userId() => (session['user'] as Map<String, dynamic>)['id'] as String;

  Future<List<String>> events() async => [for (final item in (await harness.authorized('GET', ApiPaths.securityEvents, session)).body['items'] as List<dynamic>) (item as Map<String, dynamic>)['kind'] as String];

  Future<List<dynamic>> risk(Map<String, dynamic> body) async => (await harness.authorized('POST', ApiPaths.paymentRisk, session, body: body)).body['reasons'] as List<dynamic>;

  Future<Map<String, dynamic>> resetPin({Object? nic, String pinHash = 'hash-new'}) async {
    harness.now = harness.now.add(AuthMockModule.resendDelay);
    final verification = await harness.verify();
    return (await harness.send('POST', ApiPaths.pinReset, body: {'device': harness.device, 'nic': ?nic, 'pinHash': pinHash, 'registrationToken': verification['registrationToken']})).body;
  }

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  group('security activity and devices', () {
    test('records the account being created', () async => expect(await events(), [MockSecurityLog.accountCreated]));

    test('lists this phone as the trusted device', () async {
      final items = (await harness.authorized('GET', ApiPaths.devices, session)).body['items'] as List<dynamic>;
      final device = items.single as Map<String, dynamic>;
      expect(device['id'], MockApiHarness.deviceId);
      expect(device['isCurrent'], isTrue);
      expect(device['hasBiometricKey'], isFalse);
    });

    test('signing in again on the same phone keeps it trusted since the first time', () async {
      final boundAt = harness.store.find(MockCollections.devices, MockApiHarness.deviceId)!['boundAt'];
      harness.now = harness.now.add(AuthMockModule.resendDelay);
      session = await harness.login();
      expect(harness.store.find(MockCollections.devices, MockApiHarness.deviceId)!['boundAt'], boundAt);
      expect(await events(), [MockSecurityLog.signedIn, MockSecurityLog.accountCreated]);
    });
  });

  group('POST /v1/auth/pin', () {
    Future<String?> change({String pinHash = 'hash-a', String newPinHash = 'hash-b'}) async => MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.pinChange, session, body: {'newPinHash': newPinHash, 'pinHash': pinHash}));

    test('needs the current PIN', () async => expect(await change(pinHash: 'hash-x'), FailureCodes.pinInvalid));

    test('refuses the same PIN', () async => expect(await change(newPinHash: 'hash-a'), FailureCodes.pinReused));

    test('changes the PIN and records it', () async {
      harness.now = harness.now.add(const Duration(minutes: 1));
      expect(await change(), isNull);
      expect(harness.store.find(MockCollections.users, userId())!['pinHash'], 'hash-b');
      expect((await events()).first, MockSecurityLog.pinChanged);
    });
  });

  group('POST /v1/auth/pin/reset', () {
    test('resets with only the phone when no NIC is on file', () async {
      final body = await resetPin();
      expect(body['accessToken'], isA<String>());
      expect(harness.store.find(MockCollections.users, userId())!['pinHash'], 'hash-new');
    });

    test('asks for the NIC on file and checks it', () async {
      final user = harness.store.find(MockCollections.users, userId())!;
      await harness.store.put(MockCollections.users, userId(), {...user, 'nic': nic});
      harness.now = harness.now.add(AuthMockModule.resendDelay);
      expect((await harness.verify())['requiresNic'], isTrue);
      expect(((await resetPin())['error'] as Map<String, dynamic>)['field'], 'nic');
      expect(((await resetPin(nic: '200012301234'))['error'] as Map<String, dynamic>)['code'], FailureCodes.nicMismatch);
      expect((await resetPin(nic: nic))['accessToken'], isA<String>());
    });

    test('clears a PIN lockout and signs out the old session', () async {
      final user = harness.store.find(MockCollections.users, userId())!;
      await harness.store.put(MockCollections.users, userId(), {...user, 'pinLockedUntil': harness.now.add(const Duration(hours: 1)).toIso8601String()});
      final oldSession = session;
      session = await resetPin();
      expect(harness.store.find(MockCollections.users, userId())!['pinLockedUntil'], isNull);
      expect(MockApiHarness.errorCode(await harness.authorized('GET', ApiPaths.wallet, oldSession)), FailureCodes.unauthorized);
      expect((await events()).first, MockSecurityLog.pinReset);
    });
  });

  group('POST /v1/payments/risk', () {
    test('flags a first payment to someone new, and not the next one', () async {
      expect(await risk({'amountCents': 10000, 'recipientPhone': fathima, 'type': 'transfer'}), [MockRisk.newPayee]);
      await harness.authorized(
        'POST',
        ApiPaths.transfers,
        session,
        body: {
          'amountCents': 10000,
          'approval': {'method': Approver.pinMethod, 'pinHash': 'hash-a'},
          'recipientPhone': fathima,
        },
        headers: {ApiHeaders.idempotencyKey: 'pin-1'},
      );
      expect(await risk({'amountCents': 10000, 'recipientPhone': fathima, 'type': 'transfer'}), isEmpty);
    });

    test('flags a large amount even at a shop', () async => expect(await risk({'amountCents': MockRisk.largeAmountCents, 'type': 'merchant'}), [MockRisk.largeAmount]));

    test('flags a phone bound well after the account was created', () async {
      final user = harness.store.find(MockCollections.users, userId())!;
      await harness.store.put(MockCollections.users, userId(), {...user, 'createdAt': harness.now.subtract(const Duration(days: 30)).toIso8601String()});
      expect(await risk({'amountCents': 10000, 'type': 'bill'}), [MockRisk.newDevice]);
    });
  });
}
