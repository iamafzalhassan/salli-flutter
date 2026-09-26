import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/payee.dart';
import '../../domain/usecases/get_recent_payees.dart';
import '../../domain/usecases/lookup_payee.dart';
import 'send_state.dart';

class SendCubit extends Cubit<SendState> {
  final GetRecentPayees _getRecentPayees;

  final LookupPayee _lookupPayee;

  SendCubit(this._getRecentPayees, this._lookupPayee) : super(const SendState());

  void clearSelection() => emit(state.copyWith(selected: () => null));

  Future<void> load() async {
    final result = await _getRecentPayees();
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoadingRecents: false,
        recents: switch (result) {
          Ok(:final value) => value,
          Err() => const [],
        },
      ),
    );
  }

  void queryChanged(String query) => emit(state.copyWith(failure: () => null, phone: () => PhoneNumber.tryParse(query)));

  void select(Payee payee) => emit(state.copyWith(failure: () => null, selected: () => payee));

  Future<void> submit() async {
    final phone = state.phone;
    if (phone == null || state.isLookingUp) return;
    emit(state.copyWith(failure: () => null, isLookingUp: true));
    final result = await _lookupPayee(phone);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(isLookingUp: false, selected: () => value),
      Err(:final failure) => state.copyWith(failure: () => failure, isLookingUp: false),
    });
  }
}
