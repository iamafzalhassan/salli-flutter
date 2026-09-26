import 'package:equatable/equatable.dart';

import 'bank.dart';
import 'bank_account.dart';

class BankPayee extends Equatable {
  final String id;
  final String nickname;

  final BankAccount account;

  const BankPayee({required this.id, required this.nickname, required this.account});

  String get displayName => nickname.isEmpty ? account.accountName : nickname;

  Bank get bank => account.bank;

  @override
  List<Object?> get props => [id, nickname, account];
}
