import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/gender.dart';
import '../../domain/entities/kyc_step.dart';
import '../../domain/entities/verification.dart';

class KycState extends Equatable {
  final bool isCheckingLiveness;
  final bool isSubmitting;

  final String challenge;
  final String fullName;
  final String nicInput;

  final String? nicBackDigest;
  final String? nicFrontDigest;
  final String? selfieDigest;

  final DateTime? dateOfBirth;

  final Failure? failure;

  final Gender? gender;

  final KycStep step;

  final Verification? result;

  const KycState({
    this.isCheckingLiveness = false,
    this.isSubmitting = false,
    this.challenge = '',
    this.fullName = '',
    this.nicInput = '',
    this.nicBackDigest,
    this.nicFrontDigest,
    this.selfieDigest,
    this.dateOfBirth,
    this.failure,
    this.gender,
    this.step = KycStep.intro,
    this.result,
  });

  KycState copyWith({
    bool? isCheckingLiveness,
    bool? isSubmitting,
    String? challenge,
    String? fullName,
    String? nicInput,
    String? Function()? nicBackDigest,
    String? Function()? nicFrontDigest,
    String? Function()? selfieDigest,
    DateTime? Function()? dateOfBirth,
    Failure? Function()? failure,
    Gender? Function()? gender,
    KycStep? step,
    Verification? Function()? result,
  }) => KycState(
    isCheckingLiveness: isCheckingLiveness ?? this.isCheckingLiveness,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    challenge: challenge ?? this.challenge,
    fullName: fullName ?? this.fullName,
    nicInput: nicInput ?? this.nicInput,
    nicBackDigest: nicBackDigest == null ? this.nicBackDigest : nicBackDigest(),
    nicFrontDigest: nicFrontDigest == null ? this.nicFrontDigest : nicFrontDigest(),
    selfieDigest: selfieDigest == null ? this.selfieDigest : selfieDigest(),
    dateOfBirth: dateOfBirth == null ? this.dateOfBirth : dateOfBirth(),
    failure: failure == null ? this.failure : failure(),
    gender: gender == null ? this.gender : gender(),
    step: step ?? this.step,
    result: result == null ? this.result : result(),
  );

  @override
  List<Object?> get props => [isCheckingLiveness, isSubmitting, challenge, fullName, nicInput, nicBackDigest, nicFrontDigest, selfieDigest, dateOfBirth, failure, gender, step, result];
}
