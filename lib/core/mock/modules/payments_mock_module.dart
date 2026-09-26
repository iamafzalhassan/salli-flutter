import '../../errors/failure_codes.dart';
import '../../network/api_headers.dart';
import '../../network/api_paths.dart';
import '../../security/approval_payload.dart';
import '../mock_authenticator.dart';
import '../mock_checkout.dart';
import '../mock_collections.dart';
import '../mock_ledger.dart';
import '../mock_module.dart';
import '../mock_principal.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_risk.dart';
import '../mock_route.dart';
import '../mock_rules.dart';
import '../mock_store.dart';
import '../mock_wallet_seeder.dart';
import 'banks_mock_module.dart';
import 'requests_mock_module.dart';

class PaymentsMockModule implements MockModule {
  static const int maxRecentPayees = 8;

  static const String transferKind = 'transfer';

  static const Map<String, String> directory = {
    '+94704445566': 'Fathima Rizna',
    '+94712223344': 'Nimal Perera',
    '+94725556677': 'Arun Kumaran',
    '+94763334455': 'Tharindu Fernando',
    '+94771112233': 'Kavindi Silva',
    '+94787778899': 'Dilini Jayawardena',
  };

  final MockAuthenticator _authenticator;

  final MockCheckout _checkout;

  final MockLedger _ledger;

  final MockRisk _risk;

  final MockStore _store;

  final MockWalletSeeder _seeder;

  const PaymentsMockModule(this._authenticator, this._checkout, this._ledger, this._risk, this._store, this._seeder);

  static ({String account, String? name})? resolve(MockStore store, String phone) {
    for (final user in store.all(MockCollections.users)) {
      if (user['phone'] == phone) return (account: MockWalletSeeder.walletAccount(user['id'] as String), name: user['displayName'] as String?);
    }
    final name = directory[phone];
    return name == null ? null : (account: directoryAccount(phone), name: name);
  }

  static String directoryAccount(String phone) => 'directory:$phone';

  Future<MockResponse> _lookup(MockRequest request) => _authenticator.guard(request, (principal) async {
    final phone = request.query['phone'];
    if (phone is! String || !MockRules.phonePattern.hasMatch(phone)) return MockResponse.error(400, FailureCodes.invalidPhone, field: 'phone');
    if (_isSelf(principal, phone)) return MockResponse.error(422, FailureCodes.cannotPaySelf);
    final payee = resolve(_store, phone);
    if (payee == null) return MockResponse.error(404, FailureCodes.payeeNotFound);
    return MockResponse.ok({'name': payee.name, 'phone': phone});
  });

  Future<MockResponse> _recent(MockRequest request) => _authenticator.guard(request, (principal) async {
    await _seeder.ensureSeeded(principal.userId);
    final account = MockWalletSeeder.walletAccount(principal.userId);
    final payees = <String, String>{};
    for (final transaction in _ledger.transactionsFor(account).where((transaction) => transaction['type'] == MockWalletSeeder.transfer)) {
      final isCredit = transaction['creditAccount'] == account;
      final phone = transaction[isCredit ? 'debitPhone' : 'creditPhone'] as String?;
      if (phone != null && payees.length < maxRecentPayees) payees.putIfAbsent(phone, () => transaction[isCredit ? 'debitName' : 'creditName'] as String);
    }
    return MockResponse.ok({
      'items': [
        for (final MapEntry(key: phone, value: name) in payees.entries) {'name': name, 'phone': phone},
      ],
    });
  });

  Future<MockResponse> _transfer(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final note = request.body['note'];
    final invalid = MockRules.rejectKey(request) ?? MockRules.rejectAmount(amountCents) ?? MockRules.rejectNote(note);
    if (invalid != null) return invalid;
    final phone = request.body['recipientPhone'];
    if (phone is! String || !MockRules.phonePattern.hasMatch(phone)) return MockResponse.error(400, FailureCodes.invalidPhone, field: 'recipientPhone');
    if (_isSelf(principal, phone)) return MockResponse.error(422, FailureCodes.cannotPaySelf);
    final payee = resolve(_store, phone);
    if (payee == null) return MockResponse.error(404, FailureCodes.payeeNotFound);
    final requestId = request.body['requestId'];
    final moneyRequest = requestId is String ? _store.find(MockCollections.moneyRequests, requestId) : null;
    if (requestId != null) {
      final ownPhone = _store.find(MockCollections.users, principal.userId)?['phone'];
      if (moneyRequest == null || moneyRequest['toPhone'] != ownPhone) return MockResponse.error(404, FailureCodes.requestNotFound);
      if (moneyRequest['status'] != RequestsMockModule.pending) return MockResponse.error(409, FailureCodes.requestNotPending);
      if (moneyRequest['fromPhone'] != phone) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'requestId');
      if (moneyRequest['amountCents'] != amountCents) return MockResponse.error(422, FailureCodes.amountMismatch, field: 'amountCents');
    }
    final (:rejection, :transaction) = await _checkout.charge(
      principal,
      amountCents: amountCents as int,
      approval: request.body['approval'],
      approvalPayload: ApprovalPayload.transfer(amountCents: amountCents, idempotencyKey: request.header(ApiHeaders.idempotencyKey)!, recipientPhone: phone),
      creditAccount: payee.account,
      creditName: payee.name ?? phone,
      creditPhone: phone,
      meta: {'kind': transferKind, 'phone': phone, 'requestId': ?requestId},
      note: note as String?,
      type: MockWalletSeeder.transfer,
    );
    if (transaction == null) return rejection!;
    if (moneyRequest != null) {
      await _store.put(MockCollections.moneyRequests, requestId as String, {...moneyRequest, 'paidTransactionId': transaction['id'], 'status': RequestsMockModule.paid, 'updatedAt': transaction['createdAt']});
    }
    return MockResponse.created(MockRules.receipt(transaction, extra: {'recipientName': payee.name, 'recipientPhone': phone}));
  });

  Future<MockResponse> _assess(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final type = request.body['type'];
    if (amountCents is! int || amountCents <= 0) return MockResponse.error(400, FailureCodes.invalidAmount, field: 'amountCents');
    if (type is! String || type.isEmpty) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'type');
    final phone = request.body['recipientPhone'];
    final bankCode = request.body['bankCode'];
    final accountNumber = request.body['accountNumber'];
    final creditAccount = switch (type) {
      MockWalletSeeder.transfer when phone is String => resolve(_store, phone)?.account,
      BanksMockModule.transactionType when bankCode is String && accountNumber is String => BanksMockModule.bankAccount(bankCode, accountNumber),
      _ => null,
    };
    return MockResponse.ok({'reasons': _risk.assess(principal, amountCents: amountCents, creditAccount: creditAccount, type: type)});
  });

  bool _isSelf(MockPrincipal principal, String phone) => _store.find(MockCollections.users, principal.userId)?['phone'] == phone;

  @override
  List<MockRoute> get routes => [MockRoute.get(ApiPaths.payeeLookup, _lookup), MockRoute.get(ApiPaths.recentPayees, _recent), MockRoute.post(ApiPaths.transfers, _transfer), MockRoute.post(ApiPaths.paymentRisk, _assess)];
}
