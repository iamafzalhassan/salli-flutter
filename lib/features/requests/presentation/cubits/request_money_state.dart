import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/amount_input.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/payee.dart';
import '../../domain/entities/money_request.dart';

class RequestMoneyState extends Equatable {
  final bool isLookingUp;
  final bool isSubmitting;

  final int errorToken;

  final String note;

  final List<Payee> recents;

  final AmountInput input;

  final Failure? failure;

  final MoneyRequest? created;

  final Payee? payee;

  final PhoneNumber? ownPhone;
  final PhoneNumber? phone;

  const RequestMoneyState({
    this.isLookingUp = false,
    this.isSubmitting = false,
    this.errorToken = 0,
    this.note = '',
    this.recents = const [],
    this.input = const AmountInput(),
    this.failure,
    this.created,
    this.payee,
    this.ownPhone,
    this.phone,
  });

  RequestMoneyState copyWith({
    bool? isLookingUp,
    bool? isSubmitting,
    int? errorToken,
    String? note,
    List<Payee>? recents,
    AmountInput? input,
    Failure? Function()? failure,
    MoneyRequest? Function()? created,
    Payee? Function()? payee,
    PhoneNumber? Function()? ownPhone,
    PhoneNumber? Function()? phone,
  }) => RequestMoneyState(
    isLookingUp: isLookingUp ?? this.isLookingUp,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorToken: errorToken ?? this.errorToken,
    note: note ?? this.note,
    recents: recents ?? this.recents,
    input: input ?? this.input,
    failure: failure == null ? this.failure : failure(),
    created: created == null ? this.created : created(),
    payee: payee == null ? this.payee : payee(),
    ownPhone: ownPhone == null ? this.ownPhone : ownPhone(),
    phone: phone == null ? this.phone : phone(),
  );

  @override
  List<Object?> get props => [isLookingUp, isSubmitting, errorToken, note, recents, input, failure, created, payee, ownPhone, phone];
}
