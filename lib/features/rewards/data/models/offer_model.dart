import '../../../../core/utils/money.dart';
import '../../../payments/domain/entities/merchant.dart';
import '../../../payments/domain/entities/merchant_category.dart';
import '../../domain/entities/offer.dart';

class OfferModel {
  final bool isUsed;

  final int cashbackPercent;
  final int maxCashbackCents;
  final int minSpendCents;

  final String id;
  final String qr;

  final Map<String, dynamic> merchant;

  final DateTime expiresAt;

  const OfferModel({required this.isUsed, required this.cashbackPercent, required this.maxCashbackCents, required this.minSpendCents, required this.id, required this.qr, required this.merchant, required this.expiresAt});

  factory OfferModel.fromJson(Map<String, dynamic> json) => OfferModel(
    isUsed: json['isUsed'] as bool,
    cashbackPercent: json['cashbackPercent'] as int,
    maxCashbackCents: json['maxCashbackCents'] as int,
    minSpendCents: json['minSpendCents'] as int,
    id: json['id'] as String,
    qr: json['qr'] as String,
    merchant: json['merchant'] as Map<String, dynamic>,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  Offer toEntity() => Offer(
    cashbackPercent: cashbackPercent,
    expiresAt: expiresAt,
    id: id,
    isUsed: isUsed,
    maxCashback: Money(maxCashbackCents),
    merchant: Merchant(category: MerchantCategory.values.asNameMap()[merchant['category']] ?? MerchantCategory.other, city: merchant['city'] as String, id: merchant['id'] as String, name: merchant['name'] as String),
    minSpend: Money(minSpendCents),
    qr: qr,
  );
}
