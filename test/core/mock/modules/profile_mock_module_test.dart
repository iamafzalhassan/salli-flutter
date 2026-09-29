import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_collections.dart';
import 'package:salli/core/mock/mock_kyc_reviewer.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/modules/profile_mock_module.dart';
import 'package:salli/core/network/api_paths.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  String userId() => (session['user'] as Map<String, dynamic>)['id'] as String;

  Future<MockResponse> me() => harness.authorized('GET', ApiPaths.me, session);

  Future<MockResponse> update(Map<String, dynamic> body) => harness.authorized('PATCH', ApiPaths.me, session, body: body);

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  group('GET /v1/me', () {
    test('returns the signed-in member with a not started verification', () async {
      final response = await me();
      expect(response.statusCode, 200);
      expect(response.body['id'], userId());
      expect(response.body['phone'], MockApiHarness.phone);
      expect(response.body['displayName'], isNull);
      expect((response.body['verification'] as Map<String, dynamic>)['status'], MockKycReviewer.notStarted);
    });

    test('rejects a request without a session', () async {
      final response = await harness.send('GET', ApiPaths.me);
      expect(response.statusCode, 401);
      expect(MockApiHarness.errorCode(response), FailureCodes.unauthorized);
    });

    test('rejects an unsigned request', () async {
      final response = await harness.send('GET', ApiPaths.me, accessToken: session['accessToken'] as String);
      expect(response.statusCode, 401);
      expect(MockApiHarness.errorCode(response), FailureCodes.signatureInvalid);
    });
  });

  group('PATCH /v1/me', () {
    test('saves a trimmed display name and returns it from GET', () async {
      expect((await update({'displayName': '  Afzal Hassan  '})).body['displayName'], 'Afzal Hassan');
      expect((await me()).body['displayName'], 'Afzal Hassan');
    });

    test('rejects a display name that is too short', () async {
      final response = await update({'displayName': 'A'});
      expect(MockApiHarness.errorCode(response), FailureCodes.invalidName);
      expect(MockApiHarness.errorField(response), 'displayName');
    });

    test('rejects a display name that is too long', () async => expect(MockApiHarness.errorCode(await update({'displayName': 'a' * (ProfileMockModule.maxNameLength + 1)})), FailureCodes.invalidName));

    test('rejects a display name that is not text', () async => expect(MockApiHarness.errorCode(await update({'displayName': 42})), FailureCodes.invalidName));

    test('stores the date of birth as a UTC date', () async => expect((await update({'dateOfBirth': '1995-01-15T08:30:00.000Z'})).body['dateOfBirth'], '1995-01-15T00:00:00.000Z'));

    test('accepts a member who turns the minimum age today', () async {
      final today = harness.now;
      final dateOfBirth = DateTime.utc(today.year - ProfileMockModule.minAge, today.month, today.day).toIso8601String();
      expect((await update({'dateOfBirth': dateOfBirth})).statusCode, 200);
    });

    test('rejects a member under the minimum age', () async {
      final today = harness.now;
      final response = await update({'dateOfBirth': DateTime.utc(today.year - ProfileMockModule.minAge, today.month, today.day + 1).toIso8601String()});
      expect(MockApiHarness.errorCode(response), FailureCodes.invalidDateOfBirth);
      expect(MockApiHarness.errorField(response), 'dateOfBirth');
    });

    test('rejects a date of birth that cannot be read', () async => expect(MockApiHarness.errorCode(await update({'dateOfBirth': 'not-a-date'})), FailureCodes.invalidDateOfBirth));

    test('rejects a date of birth before 1901', () async => expect(MockApiHarness.errorCode(await update({'dateOfBirth': '1900-06-01T00:00:00.000Z'})), FailureCodes.invalidDateOfBirth));

    test('locks the date of birth once the member is verified', () async {
      await harness.store.put(MockCollections.users, userId(), {...harness.store.find(MockCollections.users, userId())!, 'kycStatus': MockKycReviewer.verified});
      final response = await update({'dateOfBirth': '1995-01-15T00:00:00.000Z'});
      expect(response.statusCode, 409);
      expect(MockApiHarness.errorCode(response), FailureCodes.kycAlreadySubmitted);
      expect((await update({'displayName': 'Afzal'})).body['displayName'], 'Afzal');
    });
  });
}
