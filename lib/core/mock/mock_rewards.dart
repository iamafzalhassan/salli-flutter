import 'dart:math';

import '../utils/id_generator.dart';
import 'mock_collections.dart';
import 'mock_ledger.dart';
import 'mock_notifier.dart';
import 'mock_offers.dart';
import 'mock_store.dart';
import 'mock_wallet_seeder.dart';
import 'modules/bills_mock_module.dart';
import 'modules/merchants_mock_module.dart';
import 'modules/reload_mock_module.dart';

class MockRewards {
  static const int cardMinSpendCents = 20000;
  static const int minRedeemPoints = 500;
  static const int pointStep = 100;
  static const int pointValueCents = 10;
  static const int referralRewardCents = 25000;
  static const int spendPerPointCents = 10000;
  static const int welcomeCards = 2;
  static const int welcomePoints = 120;

  static const String account = 'rewards:salli';
  static const String accountName = 'Salli Rewards';
  static const String bonusType = 'bonus';
  static const String cashbackType = 'cashback';
  static const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const String _codePrefix = 'SALLI';
  static const String scratched = 'scratched';
  static const String unscratched = 'unscratched';

  static const List<int> cardPrizesCents = [0, 1000, 2000, 2500, 5000, 10000];

  static const Set<String> cardTypes = {BillsMockModule.transactionType, MerchantsMockModule.transactionType};
  static const Set<String> earningTypes = {BillsMockModule.transactionType, MerchantsMockModule.transactionType, ReloadMockModule.transactionType};

  static const Duration referralWindow = Duration(days: 30);

  final DateTime Function() _clock;

  final MockLedger _ledger;

  final MockNotifier _notifier;

  final MockStore _store;

  final Random _random;

  MockRewards(this._ledger, this._notifier, this._store, {DateTime Function()? clock, Random? random}) : _clock = clock ?? DateTime.now, _random = random ?? Random.secure();

  Future<void> afterCharge(String userId, Map<String, dynamic> transaction) async {
    final type = transaction['type'] as String;
    if (!earningTypes.contains(type)) return;
    final amountCents = transaction['amountCents'] as int;
    final source = transaction['creditName'] as String;
    final current = await accountOf(userId);
    var rewards = {...current, 'points': (current['points'] as int) + amountCents ~/ spendPerPointCents};
    if (cardTypes.contains(type) && amountCents >= cardMinSpendCents) {
      await _issueCard(userId, source);
      await _notifier.notify(userId, MockNotifier.scratchCardEarned, params: {'merchant': source});
    }
    final meta = transaction['meta'] as Map<String, dynamic>? ?? const {};
    final offer = type == MerchantsMockModule.transactionType ? MockOffers.forMerchant(meta['merchantId']) : null;
    final usedOffers = (rewards['usedOffers'] as List<dynamic>? ?? const []).cast<String>();
    if (offer != null && amountCents >= offer.minSpendCents && !usedOffers.contains(offer.id)) {
      final cashbackCents = min(amountCents * offer.cashbackPercent ~/ 100, offer.maxCashbackCents);
      await credit(userId, cashbackCents, meta: {'offerId': offer.id}, type: cashbackType);
      rewards = {
        ...rewards,
        'cashbackCents': (rewards['cashbackCents'] as int) + cashbackCents,
        'usedOffers': [...usedOffers, offer.id],
      };
      await _notifier.notify(userId, MockNotifier.cashbackEarned, params: {'amountCents': cashbackCents, 'merchant': source});
    }
    await _store.put(MockCollections.rewardAccounts, userId, rewards);
  }

  Future<Map<String, dynamic>> accountOf(String userId) async {
    final existing = _store.find(MockCollections.rewardAccounts, userId);
    if (existing != null) return existing;
    final created = {'cashbackCents': 0, 'points': welcomePoints, 'referralCode': referralCodeOf(userId), 'referredBy': null, 'usedOffers': <String>[], 'userId': userId};
    await _store.put(MockCollections.rewardAccounts, userId, created);
    for (var index = 0; index < welcomeCards; index++) {
      await _issueCard(userId, accountName);
    }
    return created;
  }

  static String referralCodeOf(String userId) {
    var hash = 0;
    for (final unit in userId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return '$_codePrefix${[for (var index = 0; index < 4; index++) _codeAlphabet[(hash >> (index * 5)) % _codeAlphabet.length]].join()}';
  }

  Future<Map<String, dynamic>> credit(String userId, int amountCents, {required String type, Map<String, dynamic> meta = const {}}) async {
    final user = _store.find(MockCollections.users, userId);
    return _ledger.post(
      amountCents: amountCents,
      at: _clock().toUtc(),
      creditAccount: MockWalletSeeder.walletAccount(userId),
      creditName: user?['displayName'] as String? ?? user?['phone'] as String? ?? '',
      creditPhone: user?['phone'] as String?,
      debitAccount: account,
      debitName: accountName,
      meta: {...meta, 'kind': type},
      reference: _ledger.nextReference(),
      type: type,
    );
  }

  Future<void> _issueCard(String userId, String source) async {
    final id = IdGenerator.next();
    await _store.put(MockCollections.scratchCards, id, {
      'amountCents': cardPrizesCents[_random.nextInt(cardPrizesCents.length)],
      'id': id,
      'source': source,
      'status': unscratched,
      'userId': userId,
      'earnedAt': _clock().toUtc().toIso8601String(),
      'scratchedAt': null,
    });
  }
}
