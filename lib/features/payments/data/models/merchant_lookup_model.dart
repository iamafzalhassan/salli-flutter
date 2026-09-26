import '../../../../core/utils/money.dart';
import '../../domain/entities/recipient.dart';
import '../../domain/entities/scanned_code.dart';
import 'merchant_model.dart';

class MerchantLookupModel {
  final int? amountCents;

  final MerchantModel merchant;

  const MerchantLookupModel({this.amountCents, required this.merchant});

  factory MerchantLookupModel.fromJson(Map<String, dynamic> json) => MerchantLookupModel(amountCents: json['amountCents'] as int?, merchant: MerchantModel.fromJson(json['merchant'] as Map<String, dynamic>));

  ScannedCode toEntity(String qr) {
    final amountCents = this.amountCents;
    return ScannedCode(
      amount: amountCents == null ? null : Money(amountCents),
      recipient: MerchantRecipient(merchant: merchant.toEntity(), qr: qr),
    );
  }
}
