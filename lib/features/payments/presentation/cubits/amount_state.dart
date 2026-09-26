import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/amount_input.dart';
import '../../../../core/utils/money.dart';
import '../../../account/domain/entities/account_limits.dart';
import '../../domain/entities/payment_draft.dart';

class AmountState extends Equatable {
  final int errorToken;

  final String note;

  final AccountLimits? limits;

  final AmountInput input;

  final Failure? failure;

  final Money? balance;

  final PaymentDraft? draft;

  const AmountState({this.errorToken = 0, this.note = '', this.limits, this.input = const AmountInput(), this.failure, this.balance, this.draft});

  AmountState copyWith({int? errorToken, String? note, AccountLimits? Function()? limits, AmountInput? input, Failure? Function()? failure, Money? Function()? balance, PaymentDraft? Function()? draft}) => AmountState(
    errorToken: errorToken ?? this.errorToken,
    note: note ?? this.note,
    limits: limits == null ? this.limits : limits(),
    input: input ?? this.input,
    failure: failure == null ? this.failure : failure(),
    balance: balance == null ? this.balance : balance(),
    draft: draft == null ? this.draft : draft(),
  );

  @override
  List<Object?> get props => [errorToken, note, limits, input, failure, balance, draft];
}
