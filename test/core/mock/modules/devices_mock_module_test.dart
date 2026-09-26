import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/network/api_paths.dart';
import 'package:salli/core/security/approval_payload.dart';
import 'package:salli/core/security/approver.dart';

import '../../../helpers/mock_api_harness.dart';
import '../../../helpers/test_device_key.dart';

void main() {
  const fathima = '+94704445566';

  final harness = MockApiHarness();
  final biometricKey = TestDeviceKey.generate(21);

  late Map<String, dynamic> session;

  Future<MockResponse> enroll({String pinHash = 'hash-a', TestDeviceKey? key}) => harness.authorized('POST', ApiPaths.biometricKey, session, body: {'pinHash': pinHash, 'publicKey': (key ?? biometricKey).publicKey});

  Future<MockResponse> payWithBiometrics(TestDeviceKey signer, {String key = 'bio-1', int amountCents = 10000}) {
    final signature = signer.sign(ApprovalPayload.transfer(amountCents: amountCents, idempotencyKey: key, recipientPhone: fathima));
    return harness.authorized(
      'POST',
      ApiPaths.transfers,
      session,
      body: {
        'amountCents': amountCents,
        'approval': {'method': Approver.biometricMethod, 'signature': signature},
        'recipientPhone': fathima,
      },
      headers: {ApiHeaders.idempotencyKey: key},
    );
  }

  Future<MockResponse> knowFathima() => harness.authorized(
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

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  group('biometric key enrolment', () {
    test('requires the PIN', () async => expect(MockApiHarness.errorCode(await enroll(pinHash: 'hash-b')), FailureCodes.pinInvalid));

    test('accepts a valid key with the PIN', () async => expect((await enroll()).statusCode, 204));

    test('removing the key stops biometric approvals', () async {
      await enroll();
      expect((await harness.authorized('DELETE', ApiPaths.biometricKey, session)).statusCode, 204);
      expect(MockApiHarness.errorCode(await payWithBiometrics(biometricKey)), FailureCodes.biometricNotEnrolled);
    });
  });

  group('biometric payment approval', () {
    test('is refused before enrolment', () async => expect(MockApiHarness.errorCode(await payWithBiometrics(biometricKey)), FailureCodes.biometricNotEnrolled));

    test('asks for the PIN instead when paying someone new', () async {
      await enroll();
      expect(MockApiHarness.errorCode(await payWithBiometrics(biometricKey)), FailureCodes.stepUpRequired);
    });

    test('approves a payment signed by the enrolled key', () async {
      await enroll();
      await knowFathima();
      expect((await payWithBiometrics(biometricKey)).statusCode, 201);
    });

    test('rejects a signature from another key without touching the PIN counter', () async {
      await enroll();
      await knowFathima();
      expect(MockApiHarness.errorCode(await payWithBiometrics(TestDeviceKey.generate(22))), FailureCodes.approvalInvalid);
      expect((await payWithBiometrics(biometricKey, key: 'bio-2')).statusCode, 201);
    });

    test('a signature covers the amount, so it cannot be replayed for more money', () async {
      await enroll();
      final signature = biometricKey.sign(ApprovalPayload.transfer(amountCents: 10000, idempotencyKey: 'bio-3', recipientPhone: fathima));
      final response = await harness.authorized(
        'POST',
        ApiPaths.transfers,
        session,
        body: {
          'amountCents': 900000,
          'approval': {'method': Approver.biometricMethod, 'signature': signature},
          'recipientPhone': fathima,
        },
        headers: {ApiHeaders.idempotencyKey: 'bio-3'},
      );
      expect(MockApiHarness.errorCode(response), FailureCodes.approvalInvalid);
    });
  });

  group('biometric unlock', () {
    Future<MockResponse> unlock({String nonce = 'unlock-1', TestDeviceKey? key}) => harness.authorized(
      'POST',
      ApiPaths.unlock,
      session,
      body: {'approval': harness.unlockApproval(biometricKey: key ?? biometricKey, nonce: nonce)},
    );

    test('unlocks with the enrolled key', () async {
      await enroll();
      expect((await unlock()).statusCode, 204);
    });

    test('rejects a replayed unlock approval', () async {
      await enroll();
      await unlock();
      expect(MockApiHarness.errorCode(await unlock()), FailureCodes.replayedRequest);
    });

    test('rejects another key', () async {
      await enroll();
      expect(MockApiHarness.errorCode(await unlock(key: TestDeviceKey.generate(23))), FailureCodes.approvalInvalid);
    });
  });
}
