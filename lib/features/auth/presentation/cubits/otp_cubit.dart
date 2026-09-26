import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/usecases/request_otp.dart';
import '../../domain/usecases/verify_otp.dart';
import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  static const Duration _tick = Duration(seconds: 1);

  final RequestOtp _requestOtp;

  final VerifyOtp _verifyOtp;

  late final Timer _ticker;

  OtpCubit(OtpChallenge challenge, this._requestOtp, this._verifyOtp) : super(OtpState(challenge: challenge, secondsUntilResend: _secondsUntil(challenge.resendAvailableAt))) {
    _ticker = Timer.periodic(_tick, (_) => _refreshCountdown());
  }

  void backspace() {
    if (!state.isVerifying && state.code.isNotEmpty) emit(state.copyWith(code: state.code.substring(0, state.code.length - 1)));
  }

  Future<void> codeReceived(String code) async {
    if (state.isVerifying || code.length != state.challenge.codeLength) return;
    emit(state.copyWith(code: code, failure: () => null));
    await _verify(code);
  }

  Future<void> confirm() async {
    if (!state.isVerifying && !state.isResending && state.verification == null && state.code.length == state.challenge.codeLength) await _verify(state.code);
  }

  Future<void> digitEntered(int digit) async {
    if (state.isVerifying || state.code.length == state.challenge.codeLength) return;
    final code = '${state.code}$digit';
    emit(state.copyWith(code: code, failure: () => null));
    if (code.length == state.challenge.codeLength) await _verify(code);
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    emit(state.copyWith(failure: () => null, isResending: true));
    final result = await _requestOtp(state.challenge.phone);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => OtpState(challenge: value, errorToken: state.errorToken, secondsUntilResend: _secondsUntil(value.resendAvailableAt)),
      Err(:final failure) => state.copyWith(failure: () => failure, isResending: false),
    });
  }

  static int _secondsUntil(DateTime moment) => max(0, moment.difference(DateTime.now()).inSeconds);

  void _refreshCountdown() {
    final seconds = _secondsUntil(state.challenge.resendAvailableAt);
    if (seconds != state.secondsUntilResend) emit(state.copyWith(secondsUntilResend: seconds));
  }

  Future<void> _verify(String code) async {
    emit(state.copyWith(isVerifying: true));
    final result = await _verifyOtp(state.challenge, code);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(isVerifying: false, verification: () => value),
      Err(:final failure) => state.copyWith(code: '', errorToken: state.errorToken + 1, failure: () => failure, isVerifying: false),
    });
  }

  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }
}
