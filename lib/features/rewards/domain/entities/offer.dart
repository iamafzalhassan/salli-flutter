import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../payments/domain/entities/merchant.dart';
import '../../../payments/domain/entities/recipient.dart';

class Offer extends Equatable {
  final bool isUsed;

  final int cashbackPercent;

  final String id;
  final String qr;

  final DateTime expiresAt;

  final Merchant merchant;

  final Money maxCashback;
  final Money minSpend;

  const Offer({required this.isUsed, required this.cashbackPercent, required this.id, required this.qr, required this.expiresAt, required this.merchant, required this.maxCashback, required this.minSpend});

  MerchantRecipient get recipient => MerchantRecipient(merchant: merchant, qr: qr);

  @override
  List<Object?> get props => [isUsed, cashbackPercent, id, qr, expiresAt, merchant, maxCashback, minSpend];
}
