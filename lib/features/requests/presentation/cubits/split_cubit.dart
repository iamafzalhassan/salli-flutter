import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/payee.dart';
import '../../../payments/domain/usecases/get_recent_payees.dart';
import '../../../payments/domain/usecases/lookup_payee.dart';
import '../../domain/usecases/create_split.dart';
import 'split_state.dart';

class SplitCubit extends Cubit<SplitState> {
  static const int maxParticipants = 10;

  final CreateSplit _createSplit;

  final GetRecentPayees _getRecentPayees;

  final LookupPayee _lookupPayee;

  SplitCubit(this._createSplit, this._getRecentPayees, this._lookupPayee) : super(const SplitState());

  Future<void> addPhone() async {
    final phone = state.phone;
    if (phone == null || state.isLookingUp) return;
    emit(state.copyWith(failure: () => null, isLookingUp: true));
    final result = await _lookupPayee(phone);
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(isLookingUp: false, phone: () => null));
        if (!state.participants.contains(value)) toggle(value);
      case Err(:final failure):
        emit(state.copyWith(failure: () => failure, isLookingUp: false));
    }
  }

  void includeSelfToggled(bool includeSelf) => emit(state.copyWith(includeSelf: includeSelf));

  Future<void> load() async {
    final result = await _getRecentPayees();
    if (isClosed) return;
    if (result case Ok(:final value)) emit(state.copyWith(recents: value));
  }

  void noteChanged(String note) => emit(state.copyWith(note: note));

  void phoneChanged(String input) => emit(state.copyWith(failure: () => null, phone: () => PhoneNumber.tryParse(input)));

  Future<void> submit() async {
    final total = state.total;
    if (total == null || !state.canSubmit) return;
    emit(state.copyWith(failure: () => null, isSubmitting: true));
    final note = state.note.trim();
    final result = await _createSplit(total, note.isEmpty ? null : note, [for (final payee in state.participants) payee.phone], includeSelf: state.includeSelf);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(created: () => value, isSubmitting: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isSubmitting: false),
    });
  }

  void toggle(Payee payee) {
    final participants = [...state.participants];
    if (!participants.remove(payee)) {
      if (participants.length >= maxParticipants) return;
      participants.add(payee);
    }
    emit(state.copyWith(failure: () => null, participants: participants));
  }

  void totalChanged(Money total) => emit(state.copyWith(total: () => total));
}
