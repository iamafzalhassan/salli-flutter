import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/bank_payee.dart';
import '../../domain/usecases/delete_bank_payee.dart';
import '../../domain/usecases/get_bank_payees.dart';
import 'bank_payees_state.dart';

class BankPayeesCubit extends Cubit<BankPayeesState> {
  final DeleteBankPayee _deleteBankPayee;

  final GetBankPayees _getBankPayees;

  BankPayeesCubit(this._deleteBankPayee, this._getBankPayees) : super(const BankPayeesState());

  Future<void> delete(BankPayee payee) async {
    if (state.isBusy) return;
    emit(state.copyWith(actionFailure: () => null, isBusy: true));
    final result = await _deleteBankPayee(payee.id);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => state.copyWith(
        isBusy: false,
        payees: [
          for (final existing in state.payees)
            if (existing.id != payee.id) existing,
        ],
      ),
      Err(:final failure) => state.copyWith(actionFailure: () => failure, isBusy: false),
    });
  }

  Future<void> load() async {
    if (state.payees.isEmpty) emit(state.copyWith(failure: () => null, status: BankPayeesStatus.loading));
    final result = await _getBankPayees();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(failure: () => null, payees: value, status: BankPayeesStatus.ready),
      Err(:final failure) => state.copyWith(failure: () => failure, status: state.payees.isEmpty ? BankPayeesStatus.failure : BankPayeesStatus.ready),
    });
  }
}
