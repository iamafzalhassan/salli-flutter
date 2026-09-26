import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/security/biometric_prompt_text.dart';
import '../../../../core/security/pin_policy.dart';
import '../../domain/usecases/get_biometric_status.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/unlock_app.dart';
import 'unlock_state.dart';

class UnlockCubit extends Cubit<UnlockState> {
  final GetBiometricStatus _getBiometricStatus;

  final SignOut _signOut;

  final UnlockApp _unlockApp;

  UnlockCubit(this._getBiometricStatus, this._signOut, this._unlockApp) : super(const UnlockState());

  void backspace() {
    if (!state.isSubmitting && state.pin.isNotEmpty) emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
  }

  Future<void> confirm() async {
    if (!state.isSubmitting && state.pin.length == PinPolicy.length) await _submit(PinAuthorization(state.pin));
  }

  Future<void> digitEntered(int digit) async {
    if (state.isSubmitting || state.pin.length == PinPolicy.length) return;
    final pin = '${state.pin}$digit';
    emit(state.copyWith(failure: () => null, pin: pin));
    if (pin.length == PinPolicy.length) await _submit(PinAuthorization(pin));
  }

  Future<void> signOut() => _signOut();

  Future<void> start(BiometricPromptText prompt) async {
    final status = await _getBiometricStatus();
    if (isClosed) return;
    emit(state.copyWith(canUseBiometrics: status.canUse));
    if (status.canUse) await useBiometrics(prompt);
  }

  Future<void> useBiometrics(BiometricPromptText prompt) async {
    if (state.canUseBiometrics && !state.isSubmitting) await _submit(BiometricAuthorization(prompt));
  }

  Future<void> _submit(Authorization authorization) async {
    emit(state.copyWith(isSubmitting: true));
    final result = await _unlockApp(authorization);
    if (isClosed) return;
    if (result case Err(:final failure)) {
      final isCancelled = failure.code == FailureCodes.biometricCancelled;
      emit(
        state.copyWith(
          canUseBiometrics: state.canUseBiometrics && failure.code != FailureCodes.biometricInvalidated,
          errorToken: isCancelled ? state.errorToken : state.errorToken + 1,
          failure: () => isCancelled ? null : failure,
          isSubmitting: false,
          pin: '',
        ),
      );
    }
  }
}
