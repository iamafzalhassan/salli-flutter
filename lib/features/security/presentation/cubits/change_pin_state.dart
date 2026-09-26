import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';

enum ChangePinStep { confirm, create, current }

class ChangePinState extends Equatable {
  final bool isDone;
  final bool isSubmitting;

  final int errorToken;

  final String currentPin;
  final String firstPin;
  final String pin;

  final ChangePinStep step;

  final Failure? failure;

  const ChangePinState({this.isDone = false, this.isSubmitting = false, this.errorToken = 0, this.currentPin = '', this.firstPin = '', this.pin = '', this.step = ChangePinStep.current, this.failure});

  ChangePinState copyWith({bool? isDone, bool? isSubmitting, int? errorToken, String? currentPin, String? firstPin, String? pin, ChangePinStep? step, Failure? Function()? failure}) => ChangePinState(
    isDone: isDone ?? this.isDone,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorToken: errorToken ?? this.errorToken,
    currentPin: currentPin ?? this.currentPin,
    firstPin: firstPin ?? this.firstPin,
    pin: pin ?? this.pin,
    step: step ?? this.step,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [isDone, isSubmitting, errorToken, currentPin, firstPin, pin, step, failure];
}
