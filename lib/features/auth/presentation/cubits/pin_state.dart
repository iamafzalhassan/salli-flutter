import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';

enum PinStep { confirm, create, enter, nic }

class PinState extends Equatable {
  final bool isResetting;
  final bool isSubmitting;

  final int errorToken;

  final String firstPin;
  final String nic;
  final String pin;

  final Failure? failure;

  final PinStep step;

  const PinState({this.isResetting = false, this.isSubmitting = false, this.errorToken = 0, this.firstPin = '', this.nic = '', this.pin = '', this.failure, required this.step});

  PinState copyWith({bool? isResetting, bool? isSubmitting, int? errorToken, String? firstPin, String? nic, String? pin, Failure? Function()? failure, PinStep? step}) => PinState(
    isResetting: isResetting ?? this.isResetting,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorToken: errorToken ?? this.errorToken,
    firstPin: firstPin ?? this.firstPin,
    nic: nic ?? this.nic,
    pin: pin ?? this.pin,
    failure: failure == null ? this.failure : failure(),
    step: step ?? this.step,
  );

  @override
  List<Object?> get props => [isResetting, isSubmitting, errorToken, firstPin, nic, pin, failure, step];
}
