import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_authenticator.dart';
import 'package:salli/core/mock/mock_pin_verifier.dart';
import 'package:salli/core/mock/modules/auth_mock_module.dart';
import 'package:salli/core/network/api_paths.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  final harness = MockApiHarness();

  setUp(harness.setUp);

  tearDown(harness.tearDown);

  group('POST /v1/auth/otp', () {
    test('rejects a number that is not a Sri Lankan mobile', () async {
      final response = await harness.send('POST', ApiPaths.otp, body: {'phone': '+94112345678'});
      expect(response.statusCode, 400);
      expect(MockApiHarness.errorCode(response), FailureCodes.invalidPhone);
    });

    test('texts a six digit code', () async {
      final response = await harness.send('POST', ApiPaths.otp, body: {'phone': MockApiHarness.phone});
      expect(response.statusCode, 201);
      expect(response.body['codeLength'], AuthMockModule.codeLength);
      expect(harness.deliveredCode, hasLength(AuthMockModule.codeLength));
    });

    test('throttles a second request until the resend delay passes', () async {
      final first = (await harness.send('POST', ApiPaths.otp, body: {'phone': MockApiHarness.phone})).body['challengeId'];
      expect(MockApiHarness.errorCode(await harness.send('POST', ApiPaths.otp, body: {'phone': MockApiHarness.phone})), FailureCodes.otpRateLimited);
      harness.now = harness.now.add(AuthMockModule.resendDelay);
      expect((await harness.send('POST', ApiPaths.otp, body: {'phone': MockApiHarness.phone})).statusCode, 201);
      expect(MockApiHarness.errorCode(await harness.send('POST', ApiPaths.otpVerify, body: {'challengeId': first, 'code': '000000'})), FailureCodes.otpNotFound);
    });
  });

  group('POST /v1/auth/otp/verify', () {
    Future<String> challenge() async => (await harness.send('POST', ApiPaths.otp, body: {'phone': MockApiHarness.phone})).body['challengeId'] as String;

    Future<String?> verify(String challengeId, String code) async => MockApiHarness.errorCode(await harness.send('POST', ApiPaths.otpVerify, body: {'challengeId': challengeId, 'code': code}));

    test('returns a registration token and a salt for a new user', () async {
      final body = await harness.verify();
      expect(body['isNewUser'], isTrue);
      expect(body['registrationToken'], isA<String>());
      expect(base64Decode(body['pinSalt'] as String), hasLength(AuthMockModule.saltLength));
    });

    test('a verified code cannot be used twice', () async {
      final challengeId = await challenge();
      final code = harness.deliveredCode;
      expect(await verify(challengeId, code), isNull);
      expect(await verify(challengeId, code), FailureCodes.otpNotFound);
    });

    test('locks the challenge after five wrong codes', () async {
      final challengeId = await challenge();
      final wrong = harness.deliveredCode == '000000' ? '111111' : '000000';
      for (var attempt = 1; attempt < AuthMockModule.maxOtpAttempts; attempt++) {
        expect(await verify(challengeId, wrong), FailureCodes.otpInvalid);
      }
      expect(await verify(challengeId, wrong), FailureCodes.otpLocked);
      expect(await verify(challengeId, harness.deliveredCode), FailureCodes.otpLocked);
    });

    test('rejects an expired code', () async {
      final challengeId = await challenge();
      harness.now = harness.now.add(AuthMockModule.otpLifetime);
      expect(await verify(challengeId, harness.deliveredCode), FailureCodes.otpExpired);
    });
  });

  group('registration and sign in', () {
    test('creates an account and opens a session', () async {
      final session = await harness.register();
      expect(session['accessToken'], isA<String>());
      expect(session['refreshToken'], isA<String>());
      expect((session['user'] as Map<String, dynamic>)['phone'], MockApiHarness.phone);
    });

    test('rejects a device key that is not an uncompressed P-256 point', () async {
      final verification = await harness.verify();
      final response = await harness.send(
        'POST',
        ApiPaths.register,
        body: {
          'device': {
            ...harness.device,
            'publicKey': base64Encode([2, ...List<int>.filled(32, 1)]),
          },
          'pinHash': 'hash-a',
          'registrationToken': verification['registrationToken'],
        },
      );
      expect(MockApiHarness.errorCode(response), FailureCodes.invalidDeviceKey);
    });

    test('a registration token works only once', () async {
      final verification = await harness.verify();
      final body = {'device': harness.device, 'pinHash': 'hash-a', 'registrationToken': verification['registrationToken']};
      await harness.send('POST', ApiPaths.register, body: body);
      expect(MockApiHarness.errorCode(await harness.send('POST', ApiPaths.register, body: body)), FailureCodes.registrationInvalid);
    });

    test('a returning user keeps their salt and signs in with the same PIN hash', () async {
      final first = await harness.verify();
      await harness.send('POST', ApiPaths.register, body: {'device': harness.device, 'pinHash': 'hash-a', 'registrationToken': first['registrationToken']});
      harness.now = harness.now.add(AuthMockModule.resendDelay);
      final second = await harness.verify();
      expect(second['isNewUser'], isFalse);
      expect(second['pinSalt'], first['pinSalt']);
      final response = await harness.send('POST', ApiPaths.login, body: {'device': harness.device, 'pinHash': 'hash-a', 'registrationToken': second['registrationToken']});
      expect(response.statusCode, 200);
    });

    test('locks the PIN after five wrong attempts', () async {
      await harness.register();
      harness.now = harness.now.add(AuthMockModule.resendDelay);
      final verification = await harness.verify();
      Future<String?> login(String pinHash) async => MockApiHarness.errorCode(await harness.send('POST', ApiPaths.login, body: {'device': harness.device, 'pinHash': pinHash, 'registrationToken': verification['registrationToken']}));
      for (var attempt = 1; attempt < MockPinVerifier.maxAttempts; attempt++) {
        expect(await login('hash-b'), FailureCodes.pinInvalid);
      }
      expect(await login('hash-b'), FailureCodes.pinLocked);
      expect(await login('hash-a'), FailureCodes.pinLocked);
    });
  });

  group('session lifecycle', () {
    Future<Map<String, dynamic>> refresh(Object? refreshToken) async => (await harness.send('POST', ApiPaths.refresh, body: {'refreshToken': refreshToken}, isSigned: true)).body;

    test('refresh rotates both tokens and retires the old access token', () async {
      final session = await harness.register();
      final rotated = await refresh(session['refreshToken']);
      expect(rotated['refreshToken'], isNot(session['refreshToken']));
      expect(MockApiHarness.errorCode(await harness.authorized('GET', ApiPaths.me, session)), FailureCodes.unauthorized);
      expect((await harness.authorized('GET', ApiPaths.me, rotated)).statusCode, 200);
    });

    test('reusing a rotated refresh token revokes the whole session family', () async {
      final session = await harness.register();
      final rotated = await refresh(session['refreshToken']);
      expect(MockApiHarness.errorCode(await harness.send('POST', ApiPaths.refresh, body: {'refreshToken': session['refreshToken']}, isSigned: true)), FailureCodes.sessionRevoked);
      expect(MockApiHarness.errorCode(await harness.authorized('GET', ApiPaths.me, rotated)), FailureCodes.unauthorized);
    });

    test('refresh requires a device signature', () async {
      final session = await harness.register();
      expect(MockApiHarness.errorCode(await harness.send('POST', ApiPaths.refresh, body: {'refreshToken': session['refreshToken']})), FailureCodes.signatureInvalid);
    });

    test('an access token expires after its lifetime', () async {
      final session = await harness.register();
      harness.now = harness.now.add(MockAuthenticator.accessLifetime);
      expect(MockApiHarness.errorCode(await harness.authorized('GET', ApiPaths.me, session)), FailureCodes.tokenExpired);
    });

    test('unlock accepts the right PIN', () async {
      final session = await harness.register();
      expect((await harness.authorized('POST', ApiPaths.unlock, session, body: {'approval': harness.unlockApproval(pinHash: 'hash-a')})).statusCode, 204);
    });

    test('unlock rejects a wrong PIN and keeps the session', () async {
      final session = await harness.register();
      expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.unlock, session, body: {'approval': harness.unlockApproval(pinHash: 'hash-b')})), FailureCodes.pinInvalid);
      expect((await harness.authorized('GET', ApiPaths.me, session)).statusCode, 200);
    });

    test('locking the PIN at unlock revokes every session', () async {
      final session = await harness.register();
      for (var attempt = 1; attempt < MockPinVerifier.maxAttempts; attempt++) {
        await harness.authorized('POST', ApiPaths.unlock, session, body: {'approval': harness.unlockApproval(pinHash: 'hash-b')});
      }
      expect(MockApiHarness.errorCode(await harness.authorized('POST', ApiPaths.unlock, session, body: {'approval': harness.unlockApproval(pinHash: 'hash-b')})), FailureCodes.pinLocked);
      expect(MockApiHarness.errorCode(await harness.authorized('GET', ApiPaths.me, session)), FailureCodes.unauthorized);
    });

    test('logout ends the session', () async {
      final session = await harness.register();
      expect((await harness.authorized('POST', ApiPaths.logout, session)).statusCode, 204);
      expect(MockApiHarness.errorCode(await harness.authorized('GET', ApiPaths.me, session)), FailureCodes.unauthorized);
    });
  });
}
