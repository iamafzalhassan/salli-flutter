import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/otp_verification.dart';

class OtpState extends Equatable {
  final bool isResending;
  final bool isVerifying;

  final int errorToken;
  final int secondsUntilResend;

  final String code;

  final Failure? failure;

  final OtpChallenge challenge;

  final OtpVerification? verification;

  const OtpState({this.isResending = false, this.isVerifying = false, this.errorToken = 0, required this.secondsUntilResend, this.code = '', this.failure, required this.challenge, this.verification});

  bool get canResend => secondsUntilResend == 0 && !isResending && !isVerifying;

  OtpState copyWith({bool? isResending, bool? isVerifying, int? errorToken, int? secondsUntilResend, String? code, Failure? Function()? failure, OtpChallenge? challenge, OtpVerification? Function()? verification}) => OtpState(
    isResending: isResending ?? this.isResending,
    isVerifying: isVerifying ?? this.isVerifying,
    errorToken: errorToken ?? this.errorToken,
    secondsUntilResend: secondsUntilResend ?? this.secondsUntilResend,
    code: code ?? this.code,
    failure: failure == null ? this.failure : failure(),
    challenge: challenge ?? this.challenge,
    verification: verification == null ? this.verification : verification(),
  );

  @override
  List<Object?> get props => [isResending, isVerifying, errorToken, secondsUntilResend, code, failure, challenge, verification];
}
