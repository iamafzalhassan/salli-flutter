import 'package:equatable/equatable.dart';

import '../../../payments/domain/entities/recipient.dart';
import 'bank.dart';

class BankAccount extends Equatable {
  final String accountName;
  final String accountNumber;

  final String? branchCode;

  final Bank bank;

  const BankAccount({required this.accountName, required this.accountNumber, this.branchCode, required this.bank});

  BankRecipient get recipient => BankRecipient(accountName: accountName, accountNumber: accountNumber, bankCode: bank.code, bankName: bank.name, bankShortName: bank.shortName, branchCode: branchCode, fee: bank.fee);

  @override
  List<Object?> get props => [accountName, accountNumber, branchCode, bank];
}
