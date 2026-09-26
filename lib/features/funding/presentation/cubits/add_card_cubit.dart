import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/card_number.dart';
import '../../domain/entities/card_details.dart';
import '../../domain/usecases/add_card.dart';
import 'add_card_state.dart';

class AddCardCubit extends Cubit<AddCardState> {
  static const int _centuryBase = 2000;
  static const int _expiryDigits = 4;
  static const int _monthsPerYear = 12;

  static final RegExp _cvvPattern = RegExp(r'^\d{3,4}$');

  final AddCard _addCard;

  final DateTime Function() _clock;

  AddCardCubit(this._addCard, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now, super(const AddCardState());

  void cvvChanged(String cvv) => emit(state.copyWith(cvv: cvv, failure: () => null));

  void expiryChanged(String expiry) => emit(state.copyWith(expiry: expiry, failure: () => null));

  void numberChanged(String number) => emit(state.copyWith(failure: () => null, number: number.replaceAll(' ', '')));

  Future<void> save() async {
    if (state.isSaving) return;
    final month = state.expiry.length == _expiryDigits ? int.tryParse(state.expiry.substring(0, 2)) : null;
    final year = state.expiry.length == _expiryDigits ? int.tryParse(state.expiry.substring(2)) : null;
    final now = _clock();
    final failureCode = switch (state.number) {
      final number when !CardNumber.isValid(number) => FailureCodes.invalidCardNumber,
      _ when month == null || year == null || month < 1 || month > _monthsPerYear => FailureCodes.invalidRequest,
      _ when !DateTime(_centuryBase + year, month + 1).isAfter(now) => FailureCodes.cardExpired,
      _ when !_cvvPattern.hasMatch(state.cvv) => FailureCodes.invalidRequest,
      _ => null,
    };
    if (failureCode != null) {
      emit(state.copyWith(failure: () => Failure(failureCode)));
      return;
    }
    emit(state.copyWith(failure: () => null, isSaving: true));
    final result = await _addCard(CardDetails(cvv: state.cvv, expiryMonth: month!, expiryYear: _centuryBase + year!, number: state.number));
    if (isClosed) return;
    emit(switch (result) {
      Ok() => state.copyWith(isAdded: true, isSaving: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isSaving: false),
    });
  }
}
