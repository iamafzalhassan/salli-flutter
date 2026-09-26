import 'package:equatable/equatable.dart';

import 'biller.dart';

class SavedBiller extends Equatable {
  final String accountNumber;
  final String id;
  final String nickname;

  final Biller biller;

  const SavedBiller({required this.accountNumber, required this.id, required this.nickname, required this.biller});

  String get displayName => nickname.isEmpty ? biller.name : nickname;

  @override
  List<Object?> get props => [accountNumber, id, nickname, biller];
}
