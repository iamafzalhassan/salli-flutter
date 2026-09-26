import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';

class UnlockState extends Equatable {
  final bool canUseBiometrics;
  final bool isSubmitting;

  final int errorToken;

  final String pin;

  final Failure? failure;

  const UnlockState({this.canUseBiometrics = false, this.isSubmitting = false, this.errorToken = 0, this.pin = '', this.failure});

  UnlockState copyWith({bool? canUseBiometrics, bool? isSubmitting, int? errorToken, String? pin, Failure? Function()? failure}) => UnlockState(
    canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorToken: errorToken ?? this.errorToken,
    pin: pin ?? this.pin,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [canUseBiometrics, isSubmitting, errorToken, pin, failure];
}
