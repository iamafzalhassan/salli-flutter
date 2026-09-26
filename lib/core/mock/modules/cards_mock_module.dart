import 'dart:math';

import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../../security/approval_payload.dart';
import '../../utils/card_number.dart';
import '../../utils/id_generator.dart';
import '../mock_approval_verifier.dart';
import '../mock_authenticator.dart';
import '../mock_checkout.dart';
import '../mock_collections.dart';
import '../mock_ledger.dart';
import '../mock_module.dart';
import '../mock_principal.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_security_log.dart';
import '../mock_store.dart';
import '../mock_wallet_seeder.dart';

class CardsMockModule implements MockModule {
  static const int _cardDigits = 16;
  static const int _cvvDigits = 3;
  static const int defaultLimitCents = 5000000;
  static const int _last4 = 4;
  static const int maxLimitCents = 50000000;
  static const int minLimitCents = 100000;
  static const int _validityYears = 4;

  static const String active = 'active';
  static const String frozen = 'frozen';
  static const String kind = 'card';
  static const String network = 'visa';
  static const String _visaPrefix = '4';

  static const List<({Duration ago, int amountCents, String merchant})> seedPurchases = [
    (ago: Duration(days: 8), amountCents: 345000, merchant: 'Daraz'),
    (ago: Duration(days: 12), amountCents: 119000, merchant: 'Netflix'),
    (ago: Duration(days: 2, hours: 4), amountCents: 186000, merchant: 'Uber Eats'),
  ];

  static const List<({int amountCents, String merchant})> testPurchases = [(amountCents: 249000, merchant: 'Spotify'), (amountCents: 457500, merchant: 'Daraz'), (amountCents: 132000, merchant: 'Uber Eats')];

  static const Duration spendWindow = Duration(days: 30);

  final DateTime Function() _clock;

  final MockApprovalVerifier _approvalVerifier;

  final MockAuthenticator _authenticator;

  final MockCheckout _checkout;

  final MockLedger _ledger;

  final MockSecurityLog _securityLog;

  final MockStore _store;

  final MockWalletSeeder _seeder;

  final Random _random = Random.secure();

  CardsMockModule(this._approvalVerifier, this._authenticator, this._checkout, this._ledger, this._securityLog, this._store, this._seeder, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static String merchantAccount(String merchant) => 'card_merchant:$merchant';

  Future<MockResponse> _cards(MockRequest request) => _authenticator.guard(
    request,
    (principal) async => MockResponse.ok({
      'items': [_cardJson(await _cardOf(principal))],
    }),
  );

  Future<MockResponse> _reveal(MockRequest request) => _authenticator.guard(request, (principal) async {
    final card = _own(principal, request.params['id']);
    if (card == null) return MockResponse.error(404, FailureCodes.notFound);
    final approval = request.body['approval'];
    final nonce = approval is Map<String, dynamic> ? approval['nonce'] : null;
    final timestamp = approval is Map<String, dynamic> ? approval['timestamp'] : null;
    final replay = await _authenticator.claimNonce(nonce, timestamp);
    if (replay != null) return replay;
    final rejection = await _approvalVerifier.verify(principal, approval, ApprovalPayload.cardReveal(cardId: card['id'] as String, nonce: nonce as String, timestamp: timestamp as String));
    if (rejection != null) return rejection;
    return MockResponse.ok({'cvv': card['cvv'], 'expiryMonth': card['expiryMonth'], 'expiryYear': card['expiryYear'], 'number': card['number']});
  });

  Future<MockResponse> _update(MockRequest request) => _authenticator.guard(request, (principal) async {
    final card = _own(principal, request.params['id']);
    if (card == null) return MockResponse.error(404, FailureCodes.notFound);
    final status = request.body['status'];
    final limit = request.body['spendLimitCents'];
    if (status != null && status != active && status != frozen) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'status');
    if (limit != null && (limit is! int || limit < minLimitCents || limit > maxLimitCents)) return MockResponse.error(400, FailureCodes.invalidLimit, field: 'spendLimitCents');
    final updated = {...card, 'spendLimitCents': ?limit, 'status': ?status};
    await _store.put(MockCollections.cards, card['id'] as String, updated);
    if (limit != null && limit != card['spendLimitCents']) await _securityLog.record(principal.userId, MockSecurityLog.cardLimitChanged);
    if (status != null && status != card['status']) await _securityLog.record(principal.userId, status == frozen ? MockSecurityLog.cardFrozen : MockSecurityLog.cardUnfrozen);
    return MockResponse.ok(_cardJson(updated));
  });

  Future<MockResponse> _transactions(MockRequest request) => _authenticator.guard(request, (principal) async {
    final card = _own(principal, request.params['id']);
    if (card == null) return MockResponse.error(404, FailureCodes.notFound);
    return MockResponse.ok({
      'items': [
        for (final transaction in _cardTransactions(principal.userId, card['id'] as String))
          {'amountCents': -(transaction['amountCents'] as int), 'id': transaction['id'], 'merchant': transaction['creditName'], 'createdAt': transaction['createdAt']},
      ],
    });
  });

  Future<MockResponse> _testPurchase(MockRequest request) => _authenticator.guard(request, (principal) async {
    final card = _own(principal, request.params['id']);
    if (card == null) return MockResponse.error(404, FailureCodes.notFound);
    if (card['status'] == frozen) return MockResponse.error(422, FailureCodes.cardFrozen);
    final cardId = card['id'] as String;
    final purchase = testPurchases[_cardTransactions(principal.userId, cardId).length % testPurchases.length];
    if (_spent(principal.userId, cardId) + purchase.amountCents > (card['spendLimitCents'] as int)) return MockResponse.error(422, FailureCodes.cardLimitExceeded);
    final charge = await _checkout.charge(
      principal,
      amountCents: purchase.amountCents,
      creditAccount: merchantAccount(purchase.merchant),
      creditName: purchase.merchant,
      isPreApproved: true,
      meta: {'cardId': cardId, 'kind': kind, 'merchant': purchase.merchant},
      type: kind,
    );
    final transaction = charge.transaction;
    if (transaction == null) return charge.rejection!;
    return MockResponse.created({'amountCents': -purchase.amountCents, 'id': transaction['id'], 'merchant': purchase.merchant, 'createdAt': transaction['createdAt']});
  });

  Future<Map<String, dynamic>> _cardOf(MockPrincipal principal) async {
    final existing = _store.all(MockCollections.cards).where((card) => card['userId'] == principal.userId).firstOrNull;
    if (existing != null) return existing;
    await _seeder.ensureSeeded(principal.userId);
    final now = _clock().toUtc();
    final id = IdGenerator.next();
    final digits = '$_visaPrefix${[for (var index = 1; index < _cardDigits - 1; index++) _random.nextInt(10)].join()}';
    final checkDigit = [for (var digit = 0; digit < 10; digit++) digit].firstWhere((digit) => CardNumber.passesLuhn('$digits$digit'));
    final number = '$digits$checkDigit';
    final card = {
      'cvv': [for (var index = 0; index < _cvvDigits; index++) _random.nextInt(10)].join(),
      'expiryMonth': now.month,
      'expiryYear': now.year + _validityYears,
      'id': id,
      'last4': number.substring(number.length - _last4),
      'number': number,
      'spendLimitCents': defaultLimitCents,
      'status': active,
      'userId': principal.userId,
      'createdAt': now.toIso8601String(),
    };
    await _store.put(MockCollections.cards, id, card);
    final user = _store.find(MockCollections.users, principal.userId)!;
    for (final purchase in seedPurchases) {
      await _ledger.post(
        amountCents: purchase.amountCents,
        at: now.subtract(purchase.ago),
        creditAccount: merchantAccount(purchase.merchant),
        creditName: purchase.merchant,
        debitAccount: MockWalletSeeder.walletAccount(principal.userId),
        debitName: user['displayName'] as String? ?? user['phone'] as String,
        debitPhone: user['phone'] as String,
        meta: {'cardId': id, 'kind': kind, 'merchant': purchase.merchant},
        reference: _ledger.nextReference(),
        type: kind,
      );
    }
    return card;
  }

  Map<String, dynamic>? _own(MockPrincipal principal, Object? id) {
    final card = id is String ? _store.find(MockCollections.cards, id) : null;
    return card != null && card['userId'] == principal.userId ? card : null;
  }

  Map<String, dynamic> _cardJson(Map<String, dynamic> card) {
    final user = _store.find(MockCollections.users, card['userId'] as String);
    return {
      'expiryMonth': card['expiryMonth'],
      'expiryYear': card['expiryYear'],
      'holderName': ((user?['fullName'] ?? user?['displayName'] ?? '') as String).toUpperCase(),
      'id': card['id'],
      'last4': card['last4'],
      'network': network,
      'spendLimitCents': card['spendLimitCents'],
      'spentCents': _spent(card['userId'] as String, card['id'] as String),
      'status': card['status'],
    };
  }

  int _spent(String userId, String cardId) {
    final since = _clock().toUtc().subtract(spendWindow);
    return _cardTransactions(userId, cardId).where((transaction) => !DateTime.parse(transaction['createdAt'] as String).isBefore(since)).fold(0, (sum, transaction) => sum + (transaction['amountCents'] as int));
  }

  List<Map<String, dynamic>> _cardTransactions(String userId, String cardId) =>
      _ledger.transactionsFor(MockWalletSeeder.walletAccount(userId)).where((transaction) => (transaction['meta'] as Map<String, dynamic>?)?['cardId'] == cardId).toList();

  @override
  List<MockRoute> get routes => [
    MockRoute.get(ApiPaths.cards, _cards),
    MockRoute.post(ApiPaths.cardReveal, _reveal),
    MockRoute.patch(ApiPaths.card, _update),
    MockRoute.get(ApiPaths.cardTransactions, _transactions),
    MockRoute.post(ApiPaths.cardTestPurchase, _testPurchase),
  ];
}
