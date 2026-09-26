import '../../domain/entities/bank_branch.dart';

class BankBranchModel {
  final String code;
  final String name;

  const BankBranchModel({required this.code, required this.name});

  factory BankBranchModel.fromJson(Map<String, dynamic> json) => BankBranchModel(code: json['code'] as String, name: json['name'] as String);

  BankBranch toEntity() => BankBranch(code: code, name: name);
}
