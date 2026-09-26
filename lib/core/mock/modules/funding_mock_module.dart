import 'dart:math';

import '../../errors/failure_codes.dart';
import '../../network/api_headers.dart';
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
import '../mock_pin_verifier.dart';
import '../mock_principal.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_rules.dart';
import '../mock_sms_inbox.dart';
import '../mock_store.dart';
import '../mock_wallet_seeder.dart';
import 'banks_mock_module.dart';

class FundingMockModule implements MockModule {
  static const int codeLength = 6;
  static const int _last4 = 4;
  static const int maxCodeAttempts = 5;
  static const int maxTopUpCents = 10000000;
  static const int minTopUpCents = 10000;
  static const int _monthsPerYear = 12;

  static const String bankType = 'bank';
  static const String cardType = 'card';
  static const String declinedCardSuffix = '0002';
  static const String topUpType = 'top_up';
  static const String withdrawalType = 'withdrawal';

  static const Duration challengeLifetime = Duration(minutes: 3);

  static final RegExp _cvvPattern = RegExp(r'^\d{3,4}$');

  final DateTime Function() _clock;

  final MockApprovalVerifier _approvalVerifier;

  final MockAuthenticator _authenticator;

  final MockCheckout _checkout;

  final MockLedger _ledger;

  final MockSmsInbox _inbox;

  final MockStore _store;

  final MockWalletSeeder _seeder;

  final Random _random = Random.secure();

  FundingMockModule(this._approvalVerifier, this._authenticator, this._checkout, this._ledger, this._inbox, this._store, this._seeder, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static String fundingAccount(String sourceId) => 'funding:$sourceId';

  Future<MockResponse> _sources(MockRequest request) => _authenticator.guard(
    request,
    (principal) async => MockResponse.ok({
      'items': [for (final source in _sourcesOf(principal)) _sourceJson(source)],
    }),
  );

  Future<MockResponse> _linkBank(MockRequest request) => _authenticator.guard(request, (principal) async {
    final bankCode = request.body['bankCode'];
    final branchCode = request.body['branchCode'];
    final accountNumber = request.body['accountNumber'];
    final (:holder, :rejection) = BanksMockModule.resolve(bankCode, branchCode, accountNumber);
    if (holder == null) return rejection!;
    final now = _clock().toUtc();
    final id = IdGenerator.next();
    final code = [for (var index = 0; index < codeLength; index++) _random.nextInt(10)].join();
    final expiresAt = now.add(challengeLifetime).toIso8601String();
    await _store.put(MockCollections.fundingChallenges, id, {
      'accountNumber': accountNumber,
      'attempts': 0,
      'bankCode': bankCode,
      'branchCode': branchCode,
      'code': code,
      'holder': holder,
      'id': id,
      'userId': principal.userId,
      'expiresAt': expiresAt,
    });
    _inbox.deliver('Your ${BanksMockModule.directory[bankCode]!.shortName} JustPay code for linking Salli is $code. Never share it with anyone.');
    return MockResponse(202, {'challengeId': id, 'codeLength': codeLength, 'expiresAt': expiresAt});
  });

  Future<MockResponse> _verifyBank(MockRequest request) => _authenticator.guard(request, (principal) async {
    final challengeId = request.body['challengeId'];
    final code = request.body['code'];
    final challenge = challengeId is String ? _store.find(MockCollections.fundingChallenges, challengeId) : null;
    if (challenge == null || challenge['userId'] != principal.userId || code is! String) return MockResponse.error(404, FailureCodes.otpNotFound);
    final now = _clock().toUtc();
    if (!now.isBefore(DateTime.parse(challenge['expiresAt'] as String))) return MockResponse.error(422, FailureCodes.otpExpired);
    final attempts = challenge['attempts'] as int;
    if (attempts >= maxCodeAttempts) return MockResponse.error(429, FailureCodes.otpLocked);
    if (!MockPinVerifier.matches(code, challenge['code'] as String)) {
      await _store.put(MockCollections.fundingChallenges, challengeId as String, {...challenge, 'attempts': attempts + 1});
      return attempts + 1 >= maxCodeAttempts ? MockResponse.error(429, FailureCodes.otpLocked) : MockResponse.error(422, FailureCodes.otpInvalid, field: 'code');
    }
    await _store.remove(MockCollections.fundingChallenges, challengeId as String);
    final accountNumber = challenge['accountNumber'] as String;
    final bankCode = challenge['bankCode'] as String;
    final source = await _save(principal, {
      'accountNumber': accountNumber,
      'bankCode': bankCode,
      'branchCode': challenge['branchCode'],
      'holder': challenge['holder'],
      'label': BanksMockModule.directory[bankCode]!.shortName,
      'last4': accountNumber.substring(accountNumber.length - _last4),
      'type': bankType,
    });
    return MockResponse.created(_sourceJson(source));
  });

  Future<MockResponse> _addCard(MockRequest request) => _authenticator.guard(request, (principal) async {
    final number = request.body['number'];
    if (number is! String || !CardNumber.isValid(number)) return MockResponse.error(400, FailureCodes.invalidCardNumber, field: 'number');
    final month = request.body['expiryMonth'];
    final year = request.body['expiryYear'];
    if (month is! int || year is! int || month < 1 || month > _monthsPerYear) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'expiry');
    final now = _clock().toUtc();
    if (!DateTime.utc(year, month + 1).isAfter(now)) return MockResponse.error(422, FailureCodes.cardExpired, field: 'expiry');
    final cvv = request.body['cvv'];
    if (cvv is! String || !_cvvPattern.hasMatch(cvv)) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'cvv');
    if (number.endsWith(declinedCardSuffix)) return MockResponse.error(422, FailureCodes.cardDeclined);
    final brand = switch (number) {
      _ when number.startsWith('4') => 'Visa',
      _ when number.startsWith('34') || number.startsWith('37') => 'Amex',
      _ when number.startsWith('5') || number.startsWith('2') => 'Mastercard',
      _ => 'Card',
    };
    final source = await _save(principal, {'brand': brand, 'label': brand, 'last4': number.substring(number.length - _last4), 'type': cardType});
    return MockResponse.created(_sourceJson(source));
  });

  Future<MockResponse> _remove(MockRequest request) => _authenticator.guard(request, (principal) async {
    final source = _own(principal, request.params['id']);
    if (source == null) return MockResponse.error(404, FailureCodes.sourceNotFound);
    await _store.remove(MockCollections.fundingSources, source['id'] as String);
    return const MockResponse.noContent();
  });

  Future<MockResponse> _topUp(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final invalid = MockRules.rejectKey(request) ?? MockRules.rejectAmount(amountCents);
    if (invalid != null) return invalid;
    final source = _own(principal, request.body['sourceId']);
    if (source == null) return MockResponse.error(404, FailureCodes.sourceNotFound);
    if ((amountCents as int) < minTopUpCents || amountCents > maxTopUpCents) return MockResponse.error(422, FailureCodes.topUpOutOfRange, field: 'amountCents');
    final sourceId = source['id'] as String;
    final rejection = await _approvalVerifier.verify(principal, request.body['approval'], ApprovalPayload.topUp(amountCents: amountCents, idempotencyKey: request.header(ApiHeaders.idempotencyKey)!, sourceId: sourceId));
    if (rejection != null) return rejection;
    await _seeder.ensureSeeded(principal.userId);
    final user = _store.find(MockCollections.users, principal.userId)!;
    final transaction = await _ledger.post(
      amountCents: amountCents,
      at: _clock().toUtc(),
      creditAccount: MockWalletSeeder.walletAccount(principal.userId),
      creditName: user['displayName'] as String? ?? user['phone'] as String,
      creditPhone: user['phone'] as String,
      debitAccount: fundingAccount(sourceId),
      debitName: '${source['label']} ••${source['last4']}',
      meta: {'kind': topUpType, 'sourceId': sourceId},
      reference: _ledger.nextReference(),
      type: topUpType,
    );
    return MockResponse.created(MockRules.receipt(transaction, extra: {'source': _sourceJson(source)}));
  });

  Future<MockResponse> _withdraw(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final invalid = MockRules.rejectKey(request) ?? MockRules.rejectAmount(amountCents);
    if (invalid != null) return invalid;
    final source = _own(principal, request.body['sourceId']);
    if (source == null) return MockResponse.error(404, FailureCodes.sourceNotFound);
    if (source['type'] != bankType) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'sourceId');
    final sourceId = source['id'] as String;
    final charge = await _checkout.charge(
      principal,
      amountCents: amountCents as int,
      approval: request.body['approval'],
      approvalPayload: ApprovalPayload.withdrawal(amountCents: amountCents, idempotencyKey: request.header(ApiHeaders.idempotencyKey)!, sourceId: sourceId),
      creditAccount: fundingAccount(sourceId),
      creditName: '${source['label']} ••${source['last4']}',
      meta: {'kind': withdrawalType, 'sourceId': sourceId},
      type: withdrawalType,
    );
    final transaction = charge.transaction;
    if (transaction == null) return charge.rejection!;
    return MockResponse.created(MockRules.receipt(transaction, extra: {'source': _sourceJson(source)}));
  });

  List<Map<String, dynamic>> _sourcesOf(MockPrincipal principal) =>
      _store.all(MockCollections.fundingSources).where((source) => source['userId'] == principal.userId).toList()..sort((first, second) => (first['createdAt'] as String).compareTo(second['createdAt'] as String));

  Map<String, dynamic> _sourceJson(Map<String, dynamic> source) => {'bankCode': source['bankCode'], 'brand': source['brand'], 'id': source['id'], 'label': source['label'], 'last4': source['last4'], 'type': source['type']};

  Future<Map<String, dynamic>> _save(MockPrincipal principal, Map<String, dynamic> fields) async {
    final id = IdGenerator.next();
    final source = {...fields, 'id': id, 'userId': principal.userId, 'createdAt': _clock().toUtc().toIso8601String()};
    await _store.put(MockCollections.fundingSources, id, source);
    return source;
  }

  Map<String, dynamic>? _own(MockPrincipal principal, Object? id) {
    final source = id is String ? _store.find(MockCollections.fundingSources, id) : null;
    return source != null && source['userId'] == principal.userId ? source : null;
  }

  @override
  List<MockRoute> get routes => [
    MockRoute.get(ApiPaths.fundingSources, _sources),
    MockRoute.post(ApiPaths.fundingBank, _linkBank),
    MockRoute.post(ApiPaths.fundingBankVerify, _verifyBank),
    MockRoute.post(ApiPaths.fundingCard, _addCard),
    MockRoute.delete(ApiPaths.fundingSource, _remove),
    MockRoute.post(ApiPaths.topUps, _topUp),
    MockRoute.post(ApiPaths.withdrawals, _withdraw),
  ];
}
