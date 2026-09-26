import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../payments/domain/entities/recipient.dart';
import 'dispute.dart';
import 'timeline_step.dart';
import 'wallet_transaction.dart';

class TransactionDetail extends Equatable {
  final String? counterpartyPhone;
  final String? note;
  final String? reference;

  final List<TimelineStep> timeline;

  final Dispute? dispute;

  final Money fee;

  final Recipient? repeatRecipient;

  final WalletTransaction transaction;

  const TransactionDetail({this.counterpartyPhone, this.note, this.reference, required this.timeline, this.dispute, required this.fee, this.repeatRecipient, required this.transaction});

  TransactionDetail withDispute(Dispute dispute) =>
      TransactionDetail(counterpartyPhone: counterpartyPhone, dispute: dispute, fee: fee, note: note, reference: reference, repeatRecipient: repeatRecipient, timeline: timeline, transaction: transaction);

  @override
  List<Object?> get props => [counterpartyPhone, note, reference, timeline, dispute, fee, repeatRecipient, transaction];
}
