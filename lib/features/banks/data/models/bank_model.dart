import '../../../../core/utils/money.dart';
import '../../domain/entities/bank.dart';

class BankModel {
  final bool branchRequired;

  final int feeCents;

  final String accountPattern;
  final String code;
  final String name;
  final String shortName;

  const BankModel({required this.branchRequired, required this.feeCents, required this.accountPattern, required this.code, required this.name, required this.shortName});

  factory BankModel.fromJson(Map<String, dynamic> json) => BankModel(
    branchRequired: json['branchRequired'] as bool,
    feeCents: json['feeCents'] as int,
    accountPattern: json['accountPattern'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    shortName: json['shortName'] as String,
  );

  Bank toEntity() => Bank(accountPattern: accountPattern, branchRequired: branchRequired, code: code, fee: Money(feeCents), name: name, shortName: shortName);
}
