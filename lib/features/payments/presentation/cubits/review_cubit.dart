import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/security/biometric_prompt_text.dart';
import '../../../../core/security/pin_policy.dart';
import '../../../auth/domain/usecases/get_biometric_status.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/step_up_reason.dart';
import '../../domain/usecases/assess_payment_risk.dart';
import '../../domain/usecases/send_payment.dart';
import 'review_state.dart';

class ReviewCubit extends Cubit<ReviewState> {
  static const int coolingOffSeconds = 10;

  static const Set<String> _pinFallbackCodes = {
    FailureCodes.approvalInvalid,
    FailureCodes.biometricCancelled,
    FailureCodes.biometricInvalidated,
    FailureCodes.biometricLockout,
    FailureCodes.biometricNotEnrolled,
    FailureCodes.biometricUnavailable,
    FailureCodes.pinInvalid,
    FailureCodes.stepUpRequired,
  };

  static const Duration _tick = Duration(seconds: 1);

  final AssessPaymentRisk _assessRisk;

  final GetBiometricStatus _getBiometricStatus;

  final PaymentDraft _draft;

  final SendPayment _sendPayment;

  Timer? _coolingOff;

  ReviewCubit(this._assessRisk, this._getBiometricStatus, this._draft, this._sendPayment) : super(const ReviewState());

  PaymentDraft get draft => _draft;

  Future<void> authorize(BiometricPromptText prompt) async {
    if (state.isSubmitting || state.isCoolingOff) return;
    if (state.canUseBiometrics) {
      await useBiometrics(prompt);
    } else {
      emit(state.copyWith(failure: () => null, isAuthorizing: true, pin: ''));
    }
  }

  Future<void> useBiometrics(BiometricPromptText prompt) async {
    if (state.canUseBiometrics && !state.isSubmitting) await _submit(BiometricAuthorization(prompt));
  }

  void backspace() {
    if (!state.isSubmitting && state.pin.isNotEmpty) emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
  }

  void cancelAuthorization() {
    if (!state.isSubmitting) emit(state.copyWith(isAuthorizing: false, pin: ''));
  }

  Future<void> confirm() async {
    if (state.isAuthorizing && !state.isSubmitting && state.pin.length == PinPolicy.length) await _submit(PinAuthorization(state.pin));
  }

  Future<void> digitEntered(int digit) async {
    if (!state.isAuthorizing || state.isSubmitting || state.pin.length == PinPolicy.length) return;
    final pin = '${state.pin}$digit';
    emit(state.copyWith(failure: () => null, pin: pin));
    if (pin.length == PinPolicy.length) await _submit(PinAuthorization(pin));
  }

  Future<void> load() async {
    final (status, risk) = await (_getBiometricStatus(), _assessRisk(_draft)).wait;
    if (isClosed) return;
    final reasons = risk is Ok<Set<StepUpReason>> ? risk.value : const <StepUpReason>{};
    emit(state.copyWith(canUseBiometrics: status.canUse && reasons.isEmpty, coolingOffSeconds: reasons.isEmpty ? 0 : coolingOffSeconds, stepUpReasons: reasons));
    _coolingOff?.cancel();
    if (reasons.isNotEmpty) _coolingOff = Timer.periodic(_tick, (_) => _countDown());
  }

  void _countDown() {
    final seconds = state.coolingOffSeconds - 1;
    if (seconds <= 0) _coolingOff?.cancel();
    emit(state.copyWith(coolingOffSeconds: seconds));
  }

  Future<void> _submit(Authorization authorization) async {
    emit(state.copyWith(failure: () => null, isSubmitting: true));
    final result = await _sendPayment(_draft, authorization);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(isSubmitting: false, receipt: () => value),
      Err(:final failure) => state.copyWith(
        canUseBiometrics: state.canUseBiometrics && failure.code != FailureCodes.biometricInvalidated && failure.code != FailureCodes.stepUpRequired,
        errorToken: failure.code == FailureCodes.biometricCancelled ? state.errorToken : state.errorToken + 1,
        failure: () => failure.code == FailureCodes.biometricCancelled ? null : failure,
        isAuthorizing: _pinFallbackCodes.contains(failure.code),
        isSubmitting: false,
        pin: '',
      ),
    });
  }

  @override
  Future<void> close() {
    _coolingOff?.cancel();
    return super.close();
  }
}
