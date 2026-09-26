import 'package:equatable/equatable.dart';

import 'biller.dart';
import 'saved_biller.dart';

class BillAccountDraft extends Equatable {
  final bool isSaved;

  final String accountNumber;
  final String nickname;

  final Biller biller;

  const BillAccountDraft({this.isSaved = false, this.accountNumber = '', this.nickname = '', required this.biller});

  BillAccountDraft.saved(SavedBiller saved) : this(accountNumber: saved.accountNumber, biller: saved.biller, isSaved: true, nickname: saved.nickname);

  @override
  List<Object?> get props => [isSaved, accountNumber, nickname, biller];
}
