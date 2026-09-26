import 'mock_qr_codes.dart';
import 'modules/merchants_mock_module.dart';

abstract final class MockOffers {
  static const List<({int cashbackPercent, String id, int maxCashbackCents, String merchantId, int minSpendCents})> all = [
    (cashbackPercent: 15, id: 'offer-pickme', maxCashbackCents: 20000, merchantId: 'LKQR00000003', minSpendCents: 50000),
    (cashbackPercent: 10, id: 'offer-java', maxCashbackCents: 30000, merchantId: 'LKQR00000004', minSpendCents: 100000),
    (cashbackPercent: 5, id: 'offer-keells', maxCashbackCents: 50000, merchantId: 'LKQR00000001', minSpendCents: 250000),
    (cashbackPercent: 3, id: 'offer-ioc', maxCashbackCents: 40000, merchantId: 'LKQR00000006', minSpendCents: 500000),
  ];

  static ({int cashbackPercent, String id, int maxCashbackCents, String merchantId, int minSpendCents})? forMerchant(Object? merchantId) => all.where((offer) => offer.merchantId == merchantId).firstOrNull;

  static Map<String, dynamic> view(({int cashbackPercent, String id, int maxCashbackCents, String merchantId, int minSpendCents}) offer, {required DateTime expiresAt, required bool isUsed}) {
    final merchant = MerchantsMockModule.directory[offer.merchantId]!;
    return {
      'cashbackPercent': offer.cashbackPercent,
      'expiresAt': expiresAt.toIso8601String(),
      'id': offer.id,
      'isUsed': isUsed,
      'maxCashbackCents': offer.maxCashbackCents,
      'merchant': {'category': merchant.category, 'city': merchant.city, 'id': offer.merchantId, 'name': merchant.name},
      'minSpendCents': offer.minSpendCents,
      'qr': MockQrCodes.merchant(offer.merchantId),
    };
  }
}
