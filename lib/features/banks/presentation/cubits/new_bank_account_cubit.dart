import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/bank_branch.dart';
import '../../domain/usecases/get_bank_branches.dart';
import '../../domain/usecases/get_banks.dart';
import '../../domain/usecases/lookup_bank_account.dart';
import '../../domain/usecases/save_bank_payee.dart';
import 'new_bank_account_state.dart';

class NewBankAccountCubit extends Cubit<NewBankAccountState> {
  final GetBankBranches _getBankBranches;

  final GetBanks _getBanks;

  final LookupBankAccount _lookupBankAccount;

  final SaveBankPayee _saveBankPayee;

  NewBankAccountCubit(this._getBankBranches, this._getBanks, this._lookupBankAccount, this._saveBankPayee) : super(const NewBankAccountState());

  void accountChanged(String accountNumber) => emit(state.copyWith(account: () => null, accountNumber: accountNumber.trim(), failure: () => null));

  Future<void> bankSelected(Bank bank) async {
    if (bank == state.bank) return;
    emit(state.copyWith(account: () => null, bank: () => bank, branch: () => null, branches: const [], failure: () => null));
    if (!bank.branchRequired) return;
    final result = await _getBankBranches(bank);
    if (isClosed || state.bank != bank) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(branches: value),
      Err(:final failure) => state.copyWith(failure: () => failure),
    });
  }

  void branchSelected(BankBranch branch) => emit(state.copyWith(account: () => null, branch: () => branch, failure: () => null));

  void clearResult() => emit(state.copyWith(recipient: () => null));

  Future<void> load() async {
    final result = await _getBanks();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(banks: value, isLoading: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isLoading: false),
    });
  }

  Future<void> lookup() async {
    final bank = state.bank;
    if (bank == null || !state.canLookup) return;
    emit(state.copyWith(failure: () => null, isLooking: true));
    final result = await _lookupBankAccount(bank, state.accountNumber, branchCode: state.branch?.code);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(account: () => value, isLooking: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isLooking: false),
    });
  }

  void nicknameChanged(String nickname) => emit(state.copyWith(nickname: nickname));

  Future<void> proceed() async {
    final account = state.account;
    if (account == null || state.isLooking) return;
    if (state.shouldSave) {
      emit(state.copyWith(isLooking: true));
      await _saveBankPayee(account, state.nickname);
      if (isClosed) return;
    }
    emit(state.copyWith(isLooking: false, recipient: () => account.recipient));
  }

  void saveToggled(bool shouldSave) => emit(state.copyWith(shouldSave: shouldSave));
}
