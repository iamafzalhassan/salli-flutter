import '../../../../core/utils/money.dart';
import '../../domain/entities/card_status.dart';
import '../../domain/entities/virtual_card.dart';

class VirtualCardModel {
  final int expiryMonth;
  final int expiryYear;
  final int spendLimitCents;
  final int spentCents;

  final String holderName;
  final String id;
  final String last4;
  final String network;
  final String status;

  const VirtualCardModel({
    required this.expiryMonth,
    required this.expiryYear,
    required this.spendLimitCents,
    required this.spentCents,
    required this.holderName,
    required this.id,
    required this.last4,
    required this.network,
    required this.status,
  });

  factory VirtualCardModel.fromJson(Map<String, dynamic> json) => VirtualCardModel(
    expiryMonth: json['expiryMonth'] as int,
    expiryYear: json['expiryYear'] as int,
    spendLimitCents: json['spendLimitCents'] as int,
    spentCents: json['spentCents'] as int,
    holderName: json['holderName'] as String,
    id: json['id'] as String,
    last4: json['last4'] as String,
    network: json['network'] as String,
    status: json['status'] as String,
  );

  VirtualCard toEntity() => VirtualCard(
    expiryMonth: expiryMonth,
    expiryYear: expiryYear,
    holderName: holderName,
    id: id,
    last4: last4,
    network: network,
    spendLimit: Money(spendLimitCents),
    spent: Money(spentCents),
    status: CardStatus.values.asNameMap()[status] ?? CardStatus.active,
  );
}
