import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/phone_number.dart';
import '../../domain/usecases/request_otp.dart';
import 'phone_state.dart';

class PhoneCubit extends Cubit<PhoneState> {
  final RequestOtp _requestOtp;

  PhoneCubit(this._requestOtp) : super(const PhoneState());

  void inputChanged(String input) {
    if (!state.isSubmitting) emit(PhoneState(input: input, phone: PhoneNumber.tryParse(input)));
  }

  Future<void> submit() async {
    final phone = state.phone;
    if (phone == null || state.isSubmitting) return;
    emit(PhoneState(input: state.input, isSubmitting: true, phone: phone));
    final result = await _requestOtp(phone);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => PhoneState(challenge: value, input: state.input, phone: phone),
      Err(:final failure) => PhoneState(failure: failure, input: state.input, phone: phone),
    });
  }
}
