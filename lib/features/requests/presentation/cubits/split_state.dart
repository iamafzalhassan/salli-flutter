import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/payee.dart';
import '../../domain/entities/bill_split.dart';

class SplitState extends Equatable {
  final bool includeSelf;
  final bool isLookingUp;
  final bool isSubmitting;

  final String note;

  final List<Payee> participants;
  final List<Payee> recents;

  final BillSplit? created;

  final Failure? failure;

  final Money? total;

  final PhoneNumber? phone;

  const SplitState({this.includeSelf = true, this.isLookingUp = false, this.isSubmitting = false, this.note = '', this.participants = const [], this.recents = const [], this.created, this.failure, this.total, this.phone});

  bool get canSubmit => (total?.isPositive ?? false) && participants.isNotEmpty && !isSubmitting;

  List<Money> get shares {
    final total = this.total;
    final count = participants.length + (includeSelf ? 1 : 0);
    return total == null || count == 0 ? const [] : total.split(count);
  }

  SplitState copyWith({
    bool? includeSelf,
    bool? isLookingUp,
    bool? isSubmitting,
    String? note,
    List<Payee>? participants,
    List<Payee>? recents,
    BillSplit? Function()? created,
    Failure? Function()? failure,
    Money? Function()? total,
    PhoneNumber? Function()? phone,
  }) => SplitState(
    includeSelf: includeSelf ?? this.includeSelf,
    isLookingUp: isLookingUp ?? this.isLookingUp,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    note: note ?? this.note,
    participants: participants ?? this.participants,
    recents: recents ?? this.recents,
    created: created == null ? this.created : created(),
    failure: failure == null ? this.failure : failure(),
    total: total == null ? this.total : total(),
    phone: phone == null ? this.phone : phone(),
  );

  @override
  List<Object?> get props => [includeSelf, isLookingUp, isSubmitting, note, participants, recents, created, failure, total, phone];
}
