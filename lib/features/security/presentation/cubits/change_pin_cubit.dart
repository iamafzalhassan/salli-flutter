import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/security/pin_policy.dart';
import '../../domain/usecases/change_pin.dart';
import 'change_pin_state.dart';

class ChangePinCubit extends Cubit<ChangePinState> {
  final ChangePin _changePin;

  bool _isCompleting = false;

  ChangePinCubit(this._changePin) : super(const ChangePinState());

  void backspace() {
    if (!state.isSubmitting && state.pin.isNotEmpty) emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
  }

  Future<void> confirm() async {
    if (!state.isSubmitting && !state.isDone && state.pin.length == PinPolicy.length) await _complete(state.pin);
  }

  Future<void> digitEntered(int digit) async {
    if (state.isSubmitting || state.isDone || state.pin.length == PinPolicy.length) return;
    final pin = '${state.pin}$digit';
    emit(state.copyWith(failure: () => null, pin: pin));
    if (pin.length == PinPolicy.length) await _complete(pin);
  }

  Future<void> _complete(String pin) async {
    if (_isCompleting) return;
    _isCompleting = true;
    try {
      await Future<void>.delayed(PinPolicy.settleDelay);
      if (isClosed) return;
      switch (state.step) {
        case ChangePinStep.current:
          emit(state.copyWith(currentPin: pin, pin: '', step: ChangePinStep.create));
        case ChangePinStep.create when PinPolicy.isWeak(pin):
          _fail(ChangePinStep.create, const Failure(FailureCodes.pinWeak));
        case ChangePinStep.create:
          emit(state.copyWith(firstPin: pin, pin: '', step: ChangePinStep.confirm));
        case ChangePinStep.confirm when pin != state.firstPin:
          _fail(ChangePinStep.create, const Failure(FailureCodes.pinMismatch));
        case ChangePinStep.confirm:
          await _submit(pin);
      }
    } finally {
      _isCompleting = false;
    }
  }

  Future<void> _submit(String pin) async {
    emit(state.copyWith(isSubmitting: true));
    final result = await _changePin(state.currentPin, pin);
    if (isClosed) return;
    switch (result) {
      case Ok():
        emit(state.copyWith(isDone: true, isSubmitting: false));
      case Err(:final failure) when failure.code == FailureCodes.pinReused:
        _fail(ChangePinStep.create, failure);
      case Err(:final failure):
        emit(state.copyWith(currentPin: '', errorToken: state.errorToken + 1, failure: () => failure, firstPin: '', isSubmitting: false, pin: '', step: ChangePinStep.current));
    }
  }

  void _fail(ChangePinStep step, Failure failure) => emit(state.copyWith(errorToken: state.errorToken + 1, failure: () => failure, firstPin: '', isSubmitting: false, pin: '', step: step));
}
