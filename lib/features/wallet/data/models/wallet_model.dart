import '../../../../core/utils/money.dart';
import '../../domain/entities/wallet.dart';

class WalletModel {
  final int balanceCents;

  final String currency;

  const WalletModel({required this.balanceCents, required this.currency});

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(balanceCents: json['balanceCents'] as int, currency: json['currency'] as String);

  Wallet toEntity() => Wallet(balance: Money(balanceCents), currency: currency);
}
