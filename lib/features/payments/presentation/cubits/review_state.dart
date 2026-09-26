import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/payment_receipt.dart';
import '../../domain/entities/step_up_reason.dart';

class ReviewState extends Equatable {
  final bool canUseBiometrics;
  final bool isAuthorizing;
  final bool isSubmitting;

  final int coolingOffSeconds;
  final int errorToken;

  final String pin;

  final Set<StepUpReason> stepUpReasons;

  final Failure? failure;

  final PaymentReceipt? receipt;

  const ReviewState({this.canUseBiometrics = false, this.isAuthorizing = false, this.isSubmitting = false, this.coolingOffSeconds = 0, this.errorToken = 0, this.pin = '', this.stepUpReasons = const {}, this.failure, this.receipt});

  bool get isCoolingOff => coolingOffSeconds > 0;

  ReviewState copyWith({
    bool? canUseBiometrics,
    bool? isAuthorizing,
    bool? isSubmitting,
    int? coolingOffSeconds,
    int? errorToken,
    String? pin,
    Set<StepUpReason>? stepUpReasons,
    Failure? Function()? failure,
    PaymentReceipt? Function()? receipt,
  }) => ReviewState(
    canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
    isAuthorizing: isAuthorizing ?? this.isAuthorizing,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    coolingOffSeconds: coolingOffSeconds ?? this.coolingOffSeconds,
    errorToken: errorToken ?? this.errorToken,
    pin: pin ?? this.pin,
    stepUpReasons: stepUpReasons ?? this.stepUpReasons,
    failure: failure == null ? this.failure : failure(),
    receipt: receipt == null ? this.receipt : receipt(),
  );

  @override
  List<Object?> get props => [canUseBiometrics, isAuthorizing, isSubmitting, coolingOffSeconds, errorToken, pin, stepUpReasons, failure, receipt];
}
