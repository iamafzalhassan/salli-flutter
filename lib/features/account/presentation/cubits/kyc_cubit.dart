import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/gender.dart';
import '../../../../core/utils/nic.dart';
import '../../domain/entities/kyc_step.dart';
import '../../domain/entities/kyc_submission.dart';
import '../../domain/usecases/submit_kyc.dart';
import 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  static const int minNameLength = 3;

  static const List<String> challenges = ['blink', 'smile', 'turnLeft', 'turnRight'];

  static const Duration defaultLivenessDelay = Duration(milliseconds: 1500);

  final Duration _livenessDelay;

  final Random _random;

  final SubmitKyc _submitKyc;

  KycCubit(this._submitKyc, [this._livenessDelay = defaultLivenessDelay, Random? random]) : _random = random ?? Random(), super(const KycState());

  void back() {
    final previous = switch (state.step) {
      KycStep.intro || KycStep.details => KycStep.intro,
      KycStep.nicFront => KycStep.details,
      KycStep.nicBack => KycStep.nicFront,
      KycStep.selfie => KycStep.nicBack,
      KycStep.review => KycStep.selfie,
      KycStep.submitted => KycStep.submitted,
    };
    emit(state.copyWith(failure: () => null, step: previous));
  }

  void confirmDetails() {
    final nic = Nic.tryParse(state.nicInput);
    final dateOfBirth = state.dateOfBirth;
    final gender = state.gender;
    final failureCode = switch (state.fullName.trim()) {
      final name when name.length < minNameLength => FailureCodes.invalidName,
      _ when nic == null => FailureCodes.invalidNic,
      _ when dateOfBirth == null || gender == null => FailureCodes.invalidDateOfBirth,
      _ when !_matches(nic, dateOfBirth, gender) => FailureCodes.nicMismatch,
      _ => null,
    };
    emit(failureCode == null ? state.copyWith(failure: () => null, step: KycStep.nicFront) : state.copyWith(failure: () => Failure(failureCode)));
  }

  void dateOfBirthChanged(DateTime dateOfBirth) => emit(state.copyWith(dateOfBirth: () => dateOfBirth, failure: () => null));

  void fullNameChanged(String fullName) => emit(state.copyWith(failure: () => null, fullName: fullName));

  void genderChanged(Gender gender) => emit(state.copyWith(failure: () => null, gender: () => gender));

  void nicBackCaptured(List<int> bytes) => emit(state.copyWith(challenge: challenges[_random.nextInt(challenges.length)], nicBackDigest: () => _digest(bytes), step: KycStep.selfie));

  void nicChanged(String nicInput) => emit(state.copyWith(failure: () => null, nicInput: nicInput));

  void nicFrontCaptured(List<int> bytes) => emit(state.copyWith(nicFrontDigest: () => _digest(bytes), step: KycStep.nicBack));

  Future<void> selfieCaptured(List<int> bytes) async {
    emit(state.copyWith(isCheckingLiveness: true, selfieDigest: () => _digest(bytes)));
    await Future<void>.delayed(_livenessDelay);
    if (!isClosed) emit(state.copyWith(isCheckingLiveness: false, step: KycStep.review));
  }

  void start() => emit(state.copyWith(step: KycStep.details));

  Future<void> submit() async {
    final nic = Nic.tryParse(state.nicInput);
    final dateOfBirth = state.dateOfBirth;
    final gender = state.gender;
    final nicBackDigest = state.nicBackDigest;
    final nicFrontDigest = state.nicFrontDigest;
    final selfieDigest = state.selfieDigest;
    if (state.isSubmitting || nic == null || dateOfBirth == null || gender == null || nicBackDigest == null || nicFrontDigest == null || selfieDigest == null) return;
    emit(state.copyWith(failure: () => null, isSubmitting: true));
    final result = await _submitKyc(
      KycSubmission(dateOfBirth: dateOfBirth, fullName: state.fullName.trim(), gender: gender, livenessChallenges: [state.challenge], nic: nic, nicBackDigest: nicBackDigest, nicFrontDigest: nicFrontDigest, selfieDigest: selfieDigest),
    );
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(isSubmitting: false, result: () => value, step: KycStep.submitted),
      Err(:final failure) => state.copyWith(failure: () => failure, isSubmitting: false),
    });
  }

  bool _matches(Nic nic, DateTime dateOfBirth, Gender gender) => nic.gender == gender && nic.dateOfBirth.year == dateOfBirth.year && nic.dateOfBirth.month == dateOfBirth.month && nic.dateOfBirth.day == dateOfBirth.day;

  String _digest(List<int> bytes) => sha256.convert(bytes).toString();
}
