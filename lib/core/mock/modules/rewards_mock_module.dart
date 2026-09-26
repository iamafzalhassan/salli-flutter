import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_module.dart';
import '../mock_notifier.dart';
import '../mock_offers.dart';
import '../mock_principal.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_rewards.dart';
import '../mock_route.dart';
import '../mock_rules.dart';
import '../mock_store.dart';

class RewardsMockModule implements MockModule {
  final DateTime Function() _clock;

  final MockAuthenticator _authenticator;

  final MockNotifier _notifier;

  final MockRewards _rewards;

  final MockStore _store;

  RewardsMockModule(this._authenticator, this._notifier, this._rewards, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<MockResponse> _summary(MockRequest request) => _authenticator.guard(request, (principal) async => MockResponse.ok(await _view(principal)));

  Future<MockResponse> _offers(MockRequest request) => _authenticator.guard(request, (principal) async {
    final used = ((await _rewards.accountOf(principal.userId))['usedOffers'] as List<dynamic>? ?? const []).cast<String>();
    final now = _clock().toUtc();
    final expiresAt = DateTime.utc(now.year, now.month + 1);
    return MockResponse.ok({
      'items': [for (final offer in MockOffers.all) MockOffers.view(offer, expiresAt: expiresAt, isUsed: used.contains(offer.id))],
    });
  });

  Future<MockResponse> _scratch(MockRequest request) => _authenticator.guard(request, (principal) async {
    final id = request.params['id'];
    final card = id is String ? _store.find(MockCollections.scratchCards, id) : null;
    if (card == null || card['userId'] != principal.userId) return MockResponse.error(404, FailureCodes.notFound);
    if (card['status'] == MockRewards.scratched) return MockResponse.ok(_cardJson(card));
    final amountCents = card['amountCents'] as int;
    final scratched = {...card, 'scratchedAt': _clock().toUtc().toIso8601String(), 'status': MockRewards.scratched};
    await _store.put(MockCollections.scratchCards, id as String, scratched);
    if (amountCents > 0) {
      await _rewards.credit(principal.userId, amountCents, meta: {'scratchCardId': id}, type: MockRewards.cashbackType);
      final account = await _rewards.accountOf(principal.userId);
      await _store.put(MockCollections.rewardAccounts, principal.userId, {...account, 'cashbackCents': (account['cashbackCents'] as int) + amountCents});
    }
    return MockResponse.ok(_cardJson(scratched));
  });

  Future<MockResponse> _redeem(MockRequest request) => _authenticator.guard(request, (principal) async {
    final missingKey = MockRules.rejectKey(request);
    if (missingKey != null) return missingKey;
    final points = request.body['points'];
    if (points is! int || points < MockRewards.minRedeemPoints || points % MockRewards.pointStep != 0) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'points');
    final account = await _rewards.accountOf(principal.userId);
    if ((account['points'] as int) < points) return MockResponse.error(422, FailureCodes.insufficientPoints, field: 'points');
    final valueCents = points * MockRewards.pointValueCents;
    await _rewards.credit(principal.userId, valueCents, meta: {'points': points}, type: MockRewards.cashbackType);
    await _store.put(MockCollections.rewardAccounts, principal.userId, {...account, 'cashbackCents': (account['cashbackCents'] as int) + valueCents, 'points': (account['points'] as int) - points});
    return MockResponse.ok(await _view(principal));
  });

  Future<MockResponse> _claim(MockRequest request) => _authenticator.guard(request, (principal) async {
    final code = request.body['code'];
    if (code is! String || code.trim().isEmpty) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'code');
    final account = await _rewards.accountOf(principal.userId);
    final referrer = _store.all(MockCollections.rewardAccounts).where((other) => other['referralCode'] == code.trim().toUpperCase()).firstOrNull;
    if (referrer == null || referrer['userId'] == principal.userId) return MockResponse.error(422, FailureCodes.referralInvalid, field: 'code');
    if (!_canClaim(principal, account)) return MockResponse.error(409, FailureCodes.referralUnavailable);
    final referrerId = referrer['userId'] as String;
    await _store.put(MockCollections.rewardAccounts, principal.userId, {...account, 'referredBy': referrerId});
    await _rewards.credit(principal.userId, MockRewards.referralRewardCents, meta: {'referrer': referrerId}, type: MockRewards.bonusType);
    await _rewards.credit(referrerId, MockRewards.referralRewardCents, meta: {'referred': principal.userId}, type: MockRewards.bonusType);
    final user = _store.find(MockCollections.users, principal.userId);
    await _notifier.notify(referrerId, MockNotifier.referralJoined, params: {'amountCents': MockRewards.referralRewardCents, 'name': user?['displayName'] ?? user?['phone']});
    return MockResponse.ok(await _view(principal));
  });

  Future<Map<String, dynamic>> _view(MockPrincipal principal) async {
    final account = await _rewards.accountOf(principal.userId);
    final cards = _store.all(MockCollections.scratchCards).where((card) => card['userId'] == principal.userId).toList()..sort((first, second) => (second['earnedAt'] as String).compareTo(first['earnedAt'] as String));
    return {
      'cashbackCents': account['cashbackCents'],
      'minRedeemPoints': MockRewards.minRedeemPoints,
      'pointStep': MockRewards.pointStep,
      'pointValueCents': MockRewards.pointValueCents,
      'points': account['points'],
      'referral': {
        'canClaim': _canClaim(principal, account),
        'code': account['referralCode'],
        'joinedCount': _store.all(MockCollections.rewardAccounts).where((other) => other['referredBy'] == principal.userId).length,
        'rewardCents': MockRewards.referralRewardCents,
      },
      'scratchCards': [for (final card in cards) _cardJson(card)],
    };
  }

  bool _canClaim(MockPrincipal principal, Map<String, dynamic> account) {
    final createdAt = DateTime.tryParse('${_store.find(MockCollections.users, principal.userId)?['createdAt'] ?? ''}');
    return account['referredBy'] == null && createdAt != null && _clock().toUtc().difference(createdAt) < MockRewards.referralWindow;
  }

  Map<String, dynamic> _cardJson(Map<String, dynamic> card) {
    final isScratched = card['status'] == MockRewards.scratched;
    return {'amountCents': isScratched ? card['amountCents'] : null, 'id': card['id'], 'source': card['source'], 'status': card['status'], 'earnedAt': card['earnedAt']};
  }

  @override
  List<MockRoute> get routes => [
    MockRoute.get(ApiPaths.rewards, _summary),
    MockRoute.get(ApiPaths.offers, _offers),
    MockRoute.post(ApiPaths.scratchCard, _scratch),
    MockRoute.post(ApiPaths.redeemPoints, _redeem),
    MockRoute.post(ApiPaths.referralClaim, _claim),
  ];
}
