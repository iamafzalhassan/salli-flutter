import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../payments/domain/entities/payment_draft.dart';
import '../../../payments/domain/entities/recipient.dart';

class PayLinkState extends Equatable {
  final bool isInvalid;

  final Failure? failure;

  final PaymentDraft? draft;

  final Recipient? recipient;

  const PayLinkState({this.isInvalid = false, this.failure, this.draft, this.recipient});

  @override
  List<Object?> get props => [isInvalid, failure, draft, recipient];
}
