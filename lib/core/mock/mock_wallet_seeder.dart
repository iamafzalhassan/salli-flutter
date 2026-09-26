import 'mock_collections.dart';
import 'mock_ledger.dart';
import 'mock_store.dart';

class MockWalletSeeder {
  static const String transfer = 'transfer';
  static const String walletPrefix = 'wallet:';

  static const List<(Duration, String, String, String?, int)> seed = [
    (Duration(days: 6), 'bonus', 'Salli', null, 2500000),
    (Duration(days: 5, hours: 6), transfer, 'Nimal Perera', '+94712223344', 750000),
    (Duration(days: 4, hours: 1), 'merchant', 'Keells Super', null, -428550),
    (Duration(days: 3, hours: 5), 'reload', 'Dialog', null, -50000),
    (Duration(days: 2, hours: 3), 'bill', 'Ceylon Electricity Board', null, -364000),
    (Duration(hours: 20), 'merchant', 'PickMe', null, -82000),
    (Duration(minutes: 35), transfer, 'Kavindi Silva', '+94771112233', -150000),
  ];

  static const Map<String, String> seedCategories = {'Keells Super': 'grocery', 'PickMe': 'transport'};

  final Map<String, Future<void>> _seeding = {};

  final DateTime Function() _clock;

  final MockLedger _ledger;

  final MockStore _store;

  MockWalletSeeder(this._ledger, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static String walletAccount(String userId) => '$walletPrefix$userId';

  Future<void> ensureSeeded(String userId) => _seeding.putIfAbsent(userId, () => _seed(userId));

  Future<void> _seed(String userId) async {
    if (_store.find(MockCollections.walletSeeds, userId) != null) return;
    final account = walletAccount(userId);
    final user = _store.find(MockCollections.users, userId);
    final ownName = user?['displayName'] as String? ?? user?['phone'] as String? ?? '';
    final ownPhone = user?['phone'] as String?;
    final now = _clock().toUtc();
    for (final (ago, type, counterpartyName, counterpartyPhone, amountCents) in seed) {
      final isCredit = amountCents > 0;
      final external = 'external:$type';
      await _ledger.post(
        amountCents: amountCents.abs(),
        at: now.subtract(ago),
        creditAccount: isCredit ? account : external,
        creditName: isCredit ? ownName : counterpartyName,
        creditPhone: isCredit ? ownPhone : counterpartyPhone,
        debitAccount: isCredit ? external : account,
        debitName: isCredit ? counterpartyName : ownName,
        debitPhone: isCredit ? counterpartyPhone : ownPhone,
        meta: {'category': ?seedCategories[counterpartyName], 'kind': type, 'phone': ?counterpartyPhone},
        type: type,
      );
    }
    await _store.put(MockCollections.walletSeeds, userId, {'seededAt': now.toIso8601String()});
  }
}
