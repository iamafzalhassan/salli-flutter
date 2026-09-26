import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/payee.dart';

class SendState extends Equatable {
  final bool isLoadingRecents;
  final bool isLookingUp;

  final List<Payee> recents;

  final Failure? failure;

  final Payee? selected;

  final PhoneNumber? phone;

  const SendState({this.isLoadingRecents = true, this.isLookingUp = false, this.recents = const [], this.failure, this.selected, this.phone});

  SendState copyWith({bool? isLoadingRecents, bool? isLookingUp, List<Payee>? recents, Failure? Function()? failure, Payee? Function()? selected, PhoneNumber? Function()? phone}) => SendState(
    isLoadingRecents: isLoadingRecents ?? this.isLoadingRecents,
    isLookingUp: isLookingUp ?? this.isLookingUp,
    recents: recents ?? this.recents,
    failure: failure == null ? this.failure : failure(),
    selected: selected == null ? this.selected : selected(),
    phone: phone == null ? this.phone : phone(),
  );

  @override
  List<Object?> get props => [isLoadingRecents, isLookingUp, recents, failure, selected, phone];
}
