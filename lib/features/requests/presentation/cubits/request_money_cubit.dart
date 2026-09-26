import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/amount_input.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/payee.dart';
import '../../../payments/domain/usecases/get_recent_payees.dart';
import '../../../payments/domain/usecases/lookup_payee.dart';
import '../../../profile/domain/usecases/get_profile.dart';
import '../../domain/usecases/create_request.dart';
import 'request_money_state.dart';

class RequestMoneyCubit extends Cubit<RequestMoneyState> {
  final CreateRequest _createRequest;

  final GetProfile _getProfile;

  final GetRecentPayees _getRecentPayees;

  final LookupPayee _lookupPayee;

  RequestMoneyCubit(this._createRequest, this._getProfile, this._getRecentPayees, this._lookupPayee) : super(const RequestMoneyState());

  void backspace() => _update(state.input.backspace());

  void changePayee() => emit(state.copyWith(failure: () => null, payee: () => null));

  void choose(Payee payee) => emit(state.copyWith(failure: () => null, payee: () => payee));

  void decimalPoint() => _update(state.input.addDecimalPoint());

  void digitEntered(int digit) => _update(state.input.append(digit));

  Future<void> load() async {
    final (profile, recents) = await (_getProfile(), _getRecentPayees()).wait;
    if (isClosed) return;
    emit(
      state.copyWith(
        ownPhone: () => switch (profile) {
          Ok(:final value) => value.phone,
          Err() => null,
        },
        recents: switch (recents) {
          Ok(:final value) => value,
          Err() => const [],
        },
      ),
    );
  }

  void noteChanged(String note) => emit(state.copyWith(note: note));

  void phoneChanged(String input) => emit(state.copyWith(failure: () => null, phone: () => PhoneNumber.tryParse(input)));

  Future<void> send() async {
    final payee = state.payee;
    final amount = state.input.money;
    if (payee == null || !amount.isPositive || state.isSubmitting) return;
    emit(state.copyWith(failure: () => null, isSubmitting: true));
    final note = state.note.trim();
    final result = await _createRequest(payee.phone, amount, note.isEmpty ? null : note);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(created: () => value, isSubmitting: false),
      Err(:final failure) => state.copyWith(errorToken: state.errorToken + 1, failure: () => failure, isSubmitting: false),
    });
  }

  Future<void> submitPhone() async {
    final phone = state.phone;
    if (phone == null || state.isLookingUp) return;
    emit(state.copyWith(failure: () => null, isLookingUp: true));
    final result = await _lookupPayee(phone);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(isLookingUp: false, payee: () => value),
      Err(:final failure) => state.copyWith(failure: () => failure, isLookingUp: false),
    });
  }

  void _update(AmountInput input) {
    if (input != state.input) emit(state.copyWith(failure: () => null, input: input));
  }
}
