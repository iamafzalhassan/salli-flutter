import 'package:equatable/equatable.dart';

class BankLinkChallenge extends Equatable {
  final int codeLength;

  final String id;

  final DateTime expiresAt;

  const BankLinkChallenge({required this.codeLength, required this.id, required this.expiresAt});

  @override
  List<Object?> get props => [codeLength, id, expiresAt];
}
