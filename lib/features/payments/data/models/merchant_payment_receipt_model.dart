import '../../../../core/utils/money.dart';
import '../../domain/entities/payment_receipt.dart';
import '../../domain/entities/recipient.dart';
import 'merchant_model.dart';

class MerchantPaymentReceiptModel {
  final int amountCents;
  final int feeCents;

  final String id;
  final String reference;

  final String? note;

  final DateTime createdAt;

  final MerchantModel merchant;

  const MerchantPaymentReceiptModel({required this.amountCents, required this.feeCents, required this.id, required this.reference, this.note, required this.createdAt, required this.merchant});

  factory MerchantPaymentReceiptModel.fromJson(Map<String, dynamic> json) => MerchantPaymentReceiptModel(
    amountCents: json['amountCents'] as int,
    feeCents: json['feeCents'] as int,
    id: json['id'] as String,
    reference: json['reference'] as String,
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    merchant: MerchantModel.fromJson(json['merchant'] as Map<String, dynamic>),
  );

  PaymentReceipt toEntity(String qr) => PaymentReceipt(
    amount: Money(amountCents),
    createdAt: createdAt,
    fee: Money(feeCents),
    id: id,
    note: note,
    recipient: MerchantRecipient(merchant: merchant.toEntity(), qr: qr),
    reference: reference,
  );
}
