import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../payments/domain/entities/recipient.dart';

class BillAccountState extends Equatable {
  final bool isLooking;
  final bool shouldSave;

  final String accountNumber;
  final String nickname;

  final Failure? failure;

  final Recipient? recipient;

  const BillAccountState({this.isLooking = false, this.shouldSave = true, this.accountNumber = '', this.nickname = '', this.failure, this.recipient});

  BillAccountState copyWith({bool? isLooking, bool? shouldSave, String? accountNumber, String? nickname, Failure? Function()? failure, Recipient? Function()? recipient}) => BillAccountState(
    isLooking: isLooking ?? this.isLooking,
    shouldSave: shouldSave ?? this.shouldSave,
    accountNumber: accountNumber ?? this.accountNumber,
    nickname: nickname ?? this.nickname,
    failure: failure == null ? this.failure : failure(),
    recipient: recipient == null ? this.recipient : recipient(),
  );

  @override
  List<Object?> get props => [isLooking, shouldSave, accountNumber, nickname, failure, recipient];
}
