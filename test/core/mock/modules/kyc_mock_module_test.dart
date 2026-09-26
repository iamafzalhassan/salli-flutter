import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/mock/mock_collections.dart';
import 'package:salli/core/mock/mock_kyc_reviewer.dart';
import 'package:salli/core/mock/mock_limits.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/network/api_paths.dart';

import '../../../helpers/mock_api_harness.dart';

void main() {
  const maleNic = '199012345678';

  final harness = MockApiHarness();

  late Map<String, dynamic> session;

  Future<MockResponse> submit({String dateOfBirth = '1990-05-02T00:00:00.000Z', String gender = 'male', String nic = maleNic}) => harness.authorized(
    'POST',
    ApiPaths.kyc,
    session,
    body: {
      'dateOfBirth': dateOfBirth,
      'documents': {'nicBack': 'b' * 64, 'nicFront': 'a' * 64, 'selfie': 'c' * 64},
      'fullName': 'Afzal Hassan',
      'gender': gender,
      'liveness': {
        'challenges': ['blink'],
        'passed': true,
      },
      'nic': nic,
    },
  );

  Future<Map<String, dynamic>> verification() async => (await harness.authorized('GET', ApiPaths.kyc, session)).body;

  setUp(() async {
    await harness.setUp();
    session = await harness.register();
  });

  tearDown(harness.tearDown);

  test('a new account is basic and not started', () async {
    final body = await verification();
    expect(body['status'], MockKycReviewer.notStarted);
    expect(body['tier'], MockLimits.basicTier);
  });

  test('a submission is checked, then verified, and the higher limits apply', () async {
    final response = await submit();
    expect(response.statusCode, 202);
    expect(response.body['status'], MockKycReviewer.pending);
    expect(response.body['maskedNic'], endsWith('5678'));
    harness.now = harness.now.add(MockKycReviewer.reviewDelay);
    expect((await verification())['status'], MockKycReviewer.verified);
    final limits = (await harness.authorized('GET', ApiPaths.limits, session)).body;
    expect(limits['tier'], MockLimits.verifiedTier);
    expect(limits['perPaymentCents'], MockLimits.tiers[MockLimits.verifiedTier]!.perPaymentCents);
  });

  test('rejects a date of birth that does not match the NIC', () async => expect(MockApiHarness.errorCode(await submit(dateOfBirth: '1990-05-03T00:00:00.000Z')), FailureCodes.nicMismatch));

  test('rejects a gender that does not match the NIC', () async => expect(MockApiHarness.errorCode(await submit(gender: 'female')), FailureCodes.nicMismatch));

  test('rejects a malformed NIC', () async => expect(MockApiHarness.errorCode(await submit(nic: '12345')), FailureCodes.invalidNic));

  test('cannot submit twice while being checked', () async {
    await submit();
    expect(MockApiHarness.errorCode(await submit()), FailureCodes.kycAlreadySubmitted);
  });

  test('an unreadable document is rejected with a reason and can be tried again', () async {
    await submit(nic: '199012340000');
    harness.now = harness.now.add(MockKycReviewer.reviewDelay);
    final body = await verification();
    expect(body['status'], MockKycReviewer.rejected);
    expect(body['rejectionReason'], MockKycReviewer.unclearReason);
    expect((await submit()).statusCode, 202);
  });

  test('a NIC verified on another account is rejected without saying so', () async {
    await harness.store.put(MockCollections.users, 'other', {'id': 'other', 'kycStatus': MockKycReviewer.verified, 'nic': maleNic, 'phone': '+94700000001'});
    expect((await submit()).statusCode, 202);
    harness.now = harness.now.add(MockKycReviewer.reviewDelay);
    expect((await verification())['rejectionReason'], MockKycReviewer.reviewFailedReason);
  });

  test('updates the name and date of birth on the profile', () async {
    final response = await harness.authorized('PATCH', ApiPaths.me, session, body: {'dateOfBirth': '1995-01-15T00:00:00.000Z', 'displayName': 'Afzal'});
    expect(response.body['displayName'], 'Afzal');
    expect(response.body['dateOfBirth'], '1995-01-15T00:00:00.000Z');
    expect(MockApiHarness.errorCode(await harness.authorized('PATCH', ApiPaths.me, session, body: {'dateOfBirth': '2020-01-01T00:00:00.000Z'})), FailureCodes.invalidDateOfBirth);
  });
}
