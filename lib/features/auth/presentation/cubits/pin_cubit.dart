import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/security/pin_policy.dart';
import '../../../../core/security/session.dart';
import '../../../../core/utils/nic.dart';
import '../../domain/entities/otp_verification.dart';
import '../../domain/usecases/create_account.dart';
import '../../domain/usecases/reset_pin.dart';
import '../../domain/usecases/sign_in.dart';
import 'pin_state.dart';

class PinCubit extends Cubit<PinState> {
  final CreateAccount _createAccount;

  final OtpVerification _verification;

  final ResetPin _resetPin;

  final SignIn _signIn;

  bool _isCompleting = false;

  PinCubit(this._createAccount, OtpVerification verification, this._resetPin, this._signIn) : _verification = verification, super(PinState(step: verification.isNewUser ? PinStep.create : PinStep.enter));

  bool get canReset => !_verification.isNewUser && !state.isResetting && !state.isSubmitting;

  void backspace() {
    if (!state.isSubmitting && state.pin.isNotEmpty) emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
  }

  Future<void> confirm() async {
    if (!state.isSubmitting && state.step != PinStep.nic && state.pin.length == PinPolicy.length) await _complete(state.pin);
  }

  Future<void> digitEntered(int digit) async {
    if (state.isSubmitting || state.step == PinStep.nic || state.pin.length == PinPolicy.length) return;
    final pin = '${state.pin}$digit';
    emit(state.copyWith(pin: pin));
    if (pin.length == PinPolicy.length) await _complete(pin);
  }

  void nicChanged(String nic) => emit(state.copyWith(failure: () => null, nic: nic));

  void startReset() {
    if (!canReset) return;
    emit(PinState(errorToken: state.errorToken, isResetting: true, step: _verification.requiresNic ? PinStep.nic : PinStep.create));
  }

  void submitNic() {
    if (state.step != PinStep.nic) return;
    if (Nic.tryParse(state.nic) == null) {
      emit(
        state.copyWith(
          errorToken: state.errorToken + 1,
          failure: () => const Failure(FailureCodes.invalidNic, field: 'nic'),
        ),
      );
      return;
    }
    emit(state.copyWith(failure: () => null, step: PinStep.create));
  }

  Future<void> _complete(String pin) async {
    if (_isCompleting) return;
    _isCompleting = true;
    try {
      await Future<void>.delayed(PinPolicy.settleDelay);
      if (isClosed) return;
      switch (state.step) {
        case PinStep.create when PinPolicy.isWeak(pin):
          _fail(PinStep.create, const Failure(FailureCodes.pinWeak));
        case PinStep.create:
          emit(state.copyWith(firstPin: pin, pin: '', step: PinStep.confirm));
        case PinStep.confirm when pin != state.firstPin:
          _fail(PinStep.create, const Failure(FailureCodes.pinMismatch));
        case PinStep.confirm when state.isResetting:
          await _submit(pin, (verification, pin) => _resetPin(verification, pin, state.nic.isEmpty ? null : state.nic));
        case PinStep.confirm:
          await _submit(pin, _createAccount.call);
        case PinStep.enter:
          await _submit(pin, _signIn.call);
        case PinStep.nic:
          break;
      }
    } finally {
      _isCompleting = false;
    }
  }

  Future<void> _submit(String pin, Future<Result<Session>> Function(OtpVerification verification, String pin) action) async {
    emit(state.copyWith(isSubmitting: true, pin: pin));
    final result = await action(_verification, pin);
    if (isClosed) return;
    if (result case Err(:final failure)) {
      _fail(switch (state.step) {
        PinStep.confirm when failure.code == FailureCodes.nicMismatch => PinStep.nic,
        PinStep.confirm => PinStep.create,
        final step => step,
      }, failure);
    }
  }

  void _fail(PinStep step, Failure failure) => emit(state.copyWith(errorToken: state.errorToken + 1, failure: () => failure, firstPin: '', isSubmitting: false, pin: '', step: step));
}
