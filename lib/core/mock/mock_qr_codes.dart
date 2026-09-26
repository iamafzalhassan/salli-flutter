import '../utils/lanka_qr.dart';
import '../utils/money.dart';
import 'modules/merchants_mock_module.dart';

abstract final class MockQrCodes {
  static const String unregisteredMerchantId = 'LKQR00000999';

  static final List<String> all = [
    merchant('LKQR00000001'),
    merchant('LKQR00000003', amount: const Money(82000), reference: 'PM58213'),
    merchant('LKQR00000004', amount: const Money(145000), reference: 'T12-0047'),
    merchant('LKQR00000002'),
    merchant('LKQR00000006', amount: const Money(1250050), reference: 'P4-1180'),
    const LankaQr.personal(amount: Money.rupees(500), name: 'Fathima Rizna', phone: '+94704445566').encode(),
    const LankaQr.personal(name: 'Nimal Perera', phone: '+94712223344').encode(),
    const LankaQr(accountId: unregisteredMerchantId, categoryCode: '5499', city: 'Matara', guid: LankaQr.merchantGuid, isDynamic: false, name: 'Kamal Stores').encode(),
  ];

  static String merchant(String merchantId, {String? reference, Money? amount}) {
    final merchant = MerchantsMockModule.directory[merchantId]!;
    return LankaQr(accountId: merchantId, amount: amount, categoryCode: merchant.categoryCode, city: merchant.city, guid: LankaQr.merchantGuid, isDynamic: amount != null, name: merchant.name, reference: reference).encode();
  }
}
