import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../banks/domain/entities/bank.dart';
import '../../../banks/domain/entities/bank_branch.dart';
import '../../../banks/domain/usecases/get_bank_branches.dart';
import '../../../banks/domain/usecases/get_banks.dart';
import '../../domain/usecases/link_bank_account.dart';
import '../../domain/usecases/verify_bank_link.dart';
import 'link_bank_state.dart';

class LinkBankCubit extends Cubit<LinkBankState> {
  final GetBankBranches _getBankBranches;

  final GetBanks _getBanks;

  final LinkBankAccount _linkBankAccount;

  final VerifyBankLink _verifyBankLink;

  LinkBankCubit(this._getBankBranches, this._getBanks, this._linkBankAccount, this._verifyBankLink) : super(const LinkBankState());

  void accountChanged(String accountNumber) => emit(state.copyWith(accountNumber: accountNumber.trim(), failure: () => null));

  Future<void> bankSelected(Bank bank) async {
    if (bank == state.bank) return;
    emit(state.copyWith(bank: () => bank, branch: () => null, branches: const [], failure: () => null));
    if (!bank.branchRequired) return;
    final result = await _getBankBranches(bank);
    if (isClosed || state.bank != bank) return;
    if (result case Ok(:final value)) emit(state.copyWith(branches: value));
  }

  void branchSelected(BankBranch branch) => emit(state.copyWith(branch: () => branch, failure: () => null));

  void codeChanged(String code) => emit(state.copyWith(code: code.trim(), failure: () => null));

  Future<void> load() async {
    final result = await _getBanks();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(banks: value),
      Err(:final failure) => state.copyWith(failure: () => failure),
    });
  }

  Future<void> sendCode() async {
    final bank = state.bank;
    if (bank == null || !state.canSendCode) return;
    emit(state.copyWith(failure: () => null, isBusy: true));
    final result = await _linkBankAccount(bank.code, state.accountNumber, branchCode: state.branch?.code);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(challenge: () => value, isBusy: false),
      Err(:final failure) => state.copyWith(failure: () => failure, isBusy: false),
    });
  }

  Future<void> verify() async {
    final challenge = state.challenge;
    if (challenge == null || state.isBusy || state.code.length != challenge.codeLength) return;
    emit(state.copyWith(failure: () => null, isBusy: true));
    final result = await _verifyBankLink(challenge.id, state.code);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => state.copyWith(isBusy: false, isLinked: true),
      Err(:final failure) => state.copyWith(failure: () => failure, isBusy: false),
    });
  }
}
