import '../../../../core/utils/money.dart';
import '../../domain/entities/card_transaction.dart';

class CardTransactionModel {
  final int amountCents;

  final String id;
  final String merchant;

  final DateTime createdAt;

  const CardTransactionModel({required this.amountCents, required this.id, required this.merchant, required this.createdAt});

  factory CardTransactionModel.fromJson(Map<String, dynamic> json) =>
      CardTransactionModel(amountCents: json['amountCents'] as int, id: json['id'] as String, merchant: json['merchant'] as String, createdAt: DateTime.parse(json['createdAt'] as String));

  CardTransaction toEntity() => CardTransaction(amount: Money(amountCents), createdAt: createdAt, id: id, merchant: merchant);
}
