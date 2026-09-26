import 'mock_collections.dart';
import 'mock_ledger.dart';
import 'mock_principal.dart';
import 'mock_store.dart';
import 'mock_wallet_seeder.dart';
import 'modules/banks_mock_module.dart';

class MockRisk {
  static const int largeAmountCents = 5000000;

  static const String largeAmount = 'large_amount';
  static const String newDevice = 'new_device';
  static const String newPayee = 'new_payee';

  static const Set<String> payeeTypes = {BanksMockModule.transactionType, MockWalletSeeder.transfer};

  static const Duration enrolmentGrace = Duration(hours: 1);
  static const Duration newDeviceWindow = Duration(days: 1);

  final DateTime Function() _clock;

  final MockLedger _ledger;

  final MockStore _store;

  MockRisk(this._ledger, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  List<String> assess(MockPrincipal principal, {required int amountCents, required String? creditAccount, required String type}) {
    final account = MockWalletSeeder.walletAccount(principal.userId);
    final isKnownPayee = creditAccount != null && _ledger.transactionsFor(account).any((transaction) => transaction['debitAccount'] == account && transaction['creditAccount'] == creditAccount);
    final boundAt = DateTime.tryParse('${_store.find(MockCollections.devices, principal.deviceId)?['boundAt'] ?? ''}');
    final createdAt = DateTime.tryParse('${_store.find(MockCollections.users, principal.userId)?['createdAt'] ?? ''}');
    final isNewDevice = boundAt != null && createdAt != null && _clock().toUtc().difference(boundAt) < newDeviceWindow && boundAt.difference(createdAt) > enrolmentGrace;
    return [if (payeeTypes.contains(type) && !isKnownPayee) newPayee, if (amountCents >= largeAmountCents) largeAmount, if (isNewDevice) newDevice];
  }
}
