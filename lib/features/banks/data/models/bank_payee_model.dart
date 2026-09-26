import '../../domain/entities/bank_payee.dart';
import 'bank_account_model.dart';

class BankPayeeModel {
  final String id;
  final String nickname;

  final BankAccountModel account;

  const BankPayeeModel({required this.id, required this.nickname, required this.account});

  factory BankPayeeModel.fromJson(Map<String, dynamic> json) => BankPayeeModel(id: json['id'] as String, nickname: json['nickname'] as String? ?? '', account: BankAccountModel.fromJson(json));

  BankPayee toEntity() => BankPayee(account: account.toEntity(), id: id, nickname: nickname);
}
