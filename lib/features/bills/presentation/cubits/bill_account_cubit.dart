import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/bill_account_draft.dart';
import '../../domain/usecases/inquire_bill.dart';
import '../../domain/usecases/save_biller.dart';
import 'bill_account_state.dart';

class BillAccountCubit extends Cubit<BillAccountState> {
  final BillAccountDraft _draft;

  final InquireBill _inquireBill;

  final SaveBiller _saveBiller;

  BillAccountCubit(this._draft, this._inquireBill, this._saveBiller) : super(BillAccountState(accountNumber: _draft.accountNumber, nickname: _draft.nickname, shouldSave: !_draft.isSaved));

  BillAccountDraft get draft => _draft;

  bool get canSubmit => _draft.biller.accepts(state.accountNumber) && !state.isLooking;

  void accountChanged(String accountNumber) => emit(state.copyWith(accountNumber: accountNumber.trim(), failure: () => null));

  void clearResult() => emit(state.copyWith(recipient: () => null));

  Future<void> load() async {
    if (_draft.isSaved) await submit();
  }

  void nicknameChanged(String nickname) => emit(state.copyWith(nickname: nickname));

  void saveToggled(bool shouldSave) => emit(state.copyWith(shouldSave: shouldSave));

  Future<void> submit() async {
    if (state.isLooking) return;
    if (!_draft.biller.accepts(state.accountNumber)) {
      emit(state.copyWith(failure: () => const Failure(FailureCodes.invalidAccountNumber)));
      return;
    }
    emit(state.copyWith(failure: () => null, isLooking: true));
    final result = await _inquireBill(_draft.biller, state.accountNumber);
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        if (state.shouldSave && !_draft.isSaved) await _saveBiller(_draft.biller, state.accountNumber, state.nickname);
        if (!isClosed) emit(state.copyWith(isLooking: false, recipient: () => value.recipient));
      case Err(:final failure):
        emit(state.copyWith(failure: () => failure, isLooking: false));
    }
  }
}
