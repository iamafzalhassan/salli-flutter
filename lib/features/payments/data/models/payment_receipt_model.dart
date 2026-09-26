import '../../../../core/utils/money.dart';
import '../../domain/entities/payment_receipt.dart';
import '../../domain/entities/recipient.dart';

class PaymentReceiptModel {
  final int amountCents;
  final int feeCents;

  final String id;
  final String reference;

  final String? note;

  final DateTime createdAt;

  const PaymentReceiptModel({required this.amountCents, required this.feeCents, required this.id, required this.reference, this.note, required this.createdAt});

  factory PaymentReceiptModel.fromJson(Map<String, dynamic> json) => PaymentReceiptModel(
    amountCents: json['amountCents'] as int,
    feeCents: json['feeCents'] as int,
    id: json['id'] as String,
    reference: json['reference'] as String,
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  PaymentReceipt toEntity(Recipient recipient) => PaymentReceipt(amount: Money(amountCents), createdAt: createdAt, fee: Money(feeCents), id: id, note: note, recipient: recipient, reference: reference);
}
