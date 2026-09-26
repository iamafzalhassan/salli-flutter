import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/recipient.dart';

class ScanState extends Equatable {
  final bool isResolving;

  final int errorToken;

  final String? rejected;

  final Failure? failure;

  final PaymentDraft? draft;

  final Recipient? recipient;

  const ScanState({this.isResolving = false, this.errorToken = 0, this.rejected, this.failure, this.draft, this.recipient});

  bool get hasResult => draft != null || recipient != null;

  ScanState copyWith({bool? isResolving, int? errorToken, String? Function()? rejected, Failure? Function()? failure, PaymentDraft? Function()? draft, Recipient? Function()? recipient}) => ScanState(
    isResolving: isResolving ?? this.isResolving,
    errorToken: errorToken ?? this.errorToken,
    rejected: rejected == null ? this.rejected : rejected(),
    failure: failure == null ? this.failure : failure(),
    draft: draft == null ? this.draft : draft(),
    recipient: recipient == null ? this.recipient : recipient(),
  );

  @override
  List<Object?> get props => [isResolving, errorToken, rejected, failure, draft, recipient];
}
