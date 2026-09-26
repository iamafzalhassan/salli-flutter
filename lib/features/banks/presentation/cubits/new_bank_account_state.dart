import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/bank_branch.dart';

class NewBankAccountState extends Equatable {
  final bool isLoading;
  final bool isLooking;
  final bool shouldSave;

  final String accountNumber;
  final String nickname;

  final List<Bank> banks;

  final List<BankBranch> branches;

  final Bank? bank;

  final BankAccount? account;

  final BankBranch? branch;

  final Failure? failure;

  final Recipient? recipient;

  const NewBankAccountState({
    this.isLoading = true,
    this.isLooking = false,
    this.shouldSave = true,
    this.accountNumber = '',
    this.nickname = '',
    this.banks = const [],
    this.branches = const [],
    this.bank,
    this.account,
    this.branch,
    this.failure,
    this.recipient,
  });

  bool get canLookup {
    final bank = this.bank;
    return bank != null && !isLooking && (!bank.branchRequired || branch != null) && bank.accepts(accountNumber);
  }

  NewBankAccountState copyWith({
    bool? isLoading,
    bool? isLooking,
    bool? shouldSave,
    String? accountNumber,
    String? nickname,
    List<Bank>? banks,
    List<BankBranch>? branches,
    Bank? Function()? bank,
    BankAccount? Function()? account,
    BankBranch? Function()? branch,
    Failure? Function()? failure,
    Recipient? Function()? recipient,
  }) => NewBankAccountState(
    isLoading: isLoading ?? this.isLoading,
    isLooking: isLooking ?? this.isLooking,
    shouldSave: shouldSave ?? this.shouldSave,
    accountNumber: accountNumber ?? this.accountNumber,
    nickname: nickname ?? this.nickname,
    banks: banks ?? this.banks,
    branches: branches ?? this.branches,
    bank: bank == null ? this.bank : bank(),
    account: account == null ? this.account : account(),
    branch: branch == null ? this.branch : branch(),
    failure: failure == null ? this.failure : failure(),
    recipient: recipient == null ? this.recipient : recipient(),
  );

  @override
  List<Object?> get props => [isLoading, isLooking, shouldSave, accountNumber, nickname, banks, branches, bank, account, branch, failure, recipient];
}
