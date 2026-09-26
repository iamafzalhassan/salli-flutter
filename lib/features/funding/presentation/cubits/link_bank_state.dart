import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../banks/domain/entities/bank.dart';
import '../../../banks/domain/entities/bank_branch.dart';
import '../../domain/entities/bank_link_challenge.dart';

class LinkBankState extends Equatable {
  final bool isBusy;
  final bool isLinked;

  final String accountNumber;
  final String code;

  final List<Bank> banks;

  final List<BankBranch> branches;

  final Bank? bank;

  final BankBranch? branch;

  final BankLinkChallenge? challenge;

  final Failure? failure;

  const LinkBankState({this.isBusy = false, this.isLinked = false, this.accountNumber = '', this.code = '', this.banks = const [], this.branches = const [], this.bank, this.branch, this.challenge, this.failure});

  bool get canSendCode {
    final bank = this.bank;
    return bank != null && !isBusy && (!bank.branchRequired || branch != null) && bank.accepts(accountNumber);
  }

  LinkBankState copyWith({
    bool? isBusy,
    bool? isLinked,
    String? accountNumber,
    String? code,
    List<Bank>? banks,
    List<BankBranch>? branches,
    Bank? Function()? bank,
    BankBranch? Function()? branch,
    BankLinkChallenge? Function()? challenge,
    Failure? Function()? failure,
  }) => LinkBankState(
    isBusy: isBusy ?? this.isBusy,
    isLinked: isLinked ?? this.isLinked,
    accountNumber: accountNumber ?? this.accountNumber,
    code: code ?? this.code,
    banks: banks ?? this.banks,
    branches: branches ?? this.branches,
    bank: bank == null ? this.bank : bank(),
    branch: branch == null ? this.branch : branch(),
    challenge: challenge == null ? this.challenge : challenge(),
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [isBusy, isLinked, accountNumber, code, banks, branches, bank, branch, challenge, failure];
}
