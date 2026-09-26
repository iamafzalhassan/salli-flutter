import '../../../../core/utils/money.dart';
import '../../domain/entities/payment_receipt.dart';
import '../../domain/entities/recipient.dart';
import 'payee_model.dart';

class TransferReceiptModel {
  final int amountCents;
  final int feeCents;

  final String id;
  final String recipientPhone;
  final String reference;

  final String? note;
  final String? recipientName;

  final DateTime createdAt;

  const TransferReceiptModel({required this.amountCents, required this.feeCents, required this.id, required this.recipientPhone, required this.reference, this.note, this.recipientName, required this.createdAt});

  factory TransferReceiptModel.fromJson(Map<String, dynamic> json) => TransferReceiptModel(
    amountCents: json['amountCents'] as int,
    feeCents: json['feeCents'] as int,
    id: json['id'] as String,
    recipientPhone: json['recipientPhone'] as String,
    reference: json['reference'] as String,
    note: json['note'] as String?,
    recipientName: json['recipientName'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  PaymentReceipt toEntity() => PaymentReceipt(
    amount: Money(amountCents),
    createdAt: createdAt,
    fee: Money(feeCents),
    id: id,
    note: note,
    recipient: PersonRecipient(PayeeModel(name: recipientName, phone: recipientPhone).toEntity()),
    reference: reference,
  );
}
