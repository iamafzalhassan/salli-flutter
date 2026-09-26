import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/gender.dart';
import 'package:salli/features/account/domain/entities/account_limits.dart';
import 'package:salli/features/account/domain/entities/account_tier.dart';
import 'package:salli/features/account/domain/entities/kyc_status.dart';
import 'package:salli/features/account/domain/entities/kyc_step.dart';
import 'package:salli/features/account/domain/entities/kyc_submission.dart';
import 'package:salli/features/account/domain/entities/verification.dart';
import 'package:salli/features/account/domain/repositories/account_repository.dart';
import 'package:salli/features/account/domain/usecases/submit_kyc.dart';
import 'package:salli/features/account/presentation/cubits/kyc_cubit.dart';

class _FakeAccountRepository implements AccountRepository {
  final List<KycSubmission> submissions = [];

  @override
  Future<Result<AccountLimits>> getLimits() => throw UnimplementedError();

  @override
  Future<Result<Verification>> getVerification() => throw UnimplementedError();

  @override
  Future<Result<Verification>> submitKyc(KycSubmission submission) async {
    submissions.add(submission);
    return const Ok(Verification(status: KycStatus.pending, tier: AccountTier.basic));
  }
}

void main() {
  late _FakeAccountRepository repository;

  KycCubit filledIn() => KycCubit(SubmitKyc(repository), Duration.zero, Random(1))
    ..start()
    ..fullNameChanged('Afzal Hassan')
    ..nicChanged('199012345678')
    ..dateOfBirthChanged(DateTime(1990, 5, 2))
    ..genderChanged(Gender.male);

  setUp(() => repository = _FakeAccountRepository());

  test('moves on once the details match the NIC', () {
    final cubit = filledIn()..confirmDetails();
    expect(cubit.state.step, KycStep.nicFront);
    expect(cubit.state.failure, isNull);
  });

  test('stops when the date of birth does not match the NIC', () {
    final cubit = filledIn()
      ..dateOfBirthChanged(DateTime(1990, 5, 3))
      ..confirmDetails();
    expect(cubit.state.step, KycStep.details);
    expect(cubit.state.failure, const Failure(FailureCodes.nicMismatch));
  });

  test('stops when the gender does not match the NIC', () {
    final cubit = filledIn()
      ..genderChanged(Gender.female)
      ..confirmDetails();
    expect(cubit.state.failure, const Failure(FailureCodes.nicMismatch));
  });

  test('asks for a longer name first', () {
    final cubit = filledIn()
      ..fullNameChanged('A')
      ..confirmDetails();
    expect(cubit.state.failure, const Failure(FailureCodes.invalidName));
  });

  test('photos become fingerprints and the flow reaches review, then submits them', () async {
    final cubit = filledIn()
      ..confirmDetails()
      ..nicFrontCaptured([1, 2, 3])
      ..nicBackCaptured([4, 5, 6]);
    expect(cubit.state.step, KycStep.selfie);
    expect(KycCubit.challenges, contains(cubit.state.challenge));
    await cubit.selfieCaptured([7, 8, 9]);
    expect(cubit.state.step, KycStep.review);
    await cubit.submit();
    final submission = repository.submissions.single;
    expect(submission.nicFrontDigest, hasLength(64));
    expect(submission.nicFrontDigest, isNot(submission.nicBackDigest));
    expect(submission.livenessChallenges, [cubit.state.challenge]);
    expect(cubit.state.step, KycStep.submitted);
  });

  test('going back returns to the previous step', () {
    final cubit = filledIn()
      ..confirmDetails()
      ..back();
    expect(cubit.state.step, KycStep.details);
  });
}
