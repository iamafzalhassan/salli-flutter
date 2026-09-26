import '../../domain/entities/bank_account.dart';
import 'bank_model.dart';

class BankAccountModel {
  final String accountName;
  final String accountNumber;

  final String? branchCode;

  final BankModel bank;

  const BankAccountModel({required this.accountName, required this.accountNumber, this.branchCode, required this.bank});

  factory BankAccountModel.fromJson(Map<String, dynamic> json) =>
      BankAccountModel(accountName: json['accountName'] as String, accountNumber: json['accountNumber'] as String, branchCode: json['branchCode'] as String?, bank: BankModel.fromJson(json['bank'] as Map<String, dynamic>));

  BankAccount toEntity() => BankAccount(accountName: accountName, accountNumber: accountNumber, bank: bank.toEntity(), branchCode: branchCode);
}
