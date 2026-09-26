import 'package:equatable/equatable.dart';

class BankBranch extends Equatable {
  final String code;
  final String name;

  const BankBranch({required this.code, required this.name});

  @override
  List<Object?> get props => [code, name];
}
