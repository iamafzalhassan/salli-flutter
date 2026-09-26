import '../../errors/failure_codes.dart';
import '../../network/api_headers.dart';
import '../../network/api_paths.dart';
import '../../security/approval_payload.dart';
import '../../utils/id_generator.dart';
import '../mock_authenticator.dart';
import '../mock_checkout.dart';
import '../mock_collections.dart';
import '../mock_module.dart';
import '../mock_principal.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_rules.dart';
import '../mock_store.dart';

class BanksMockModule implements MockModule {
  static const int feeCents = 2500;
  static const int _hashModulus = 1000003;
  static const int _hashSeed = 11;
  static const int _hashStep = 37;
  static const int maxNicknameLength = 30;

  static const String kind = 'bank';
  static const String transactionType = 'bank_transfer';
  static const String unknownAccountSuffix = '000';

  static const List<String> _holders = ['A. B. Perera', 'K. M. Silva', 'S. Jayawardena', 'R. Kumaran', 'N. Fernando', 'F. Rizna', 'T. Wijesinghe', 'M. Hassan'];

  static const Map<String, ({String accountPattern, bool branchRequired, String name, String shortName})> directory = {
    '7010': (accountPattern: r'^\d{8,10}$', branchRequired: false, name: 'Bank of Ceylon', shortName: 'BOC'),
    '7135': (accountPattern: r'^\d{15}$', branchRequired: true, name: "People's Bank", shortName: "People's"),
    '7056': (accountPattern: r'^\d{10}$', branchRequired: false, name: 'Commercial Bank of Ceylon', shortName: 'ComBank'),
    '7083': (accountPattern: r'^\d{12}$', branchRequired: false, name: 'Hatton National Bank', shortName: 'HNB'),
    '7278': (accountPattern: r'^\d{12}$', branchRequired: false, name: 'Sampath Bank', shortName: 'Sampath'),
    '7287': (accountPattern: r'^\d{16}$', branchRequired: false, name: 'Seylan Bank', shortName: 'Seylan'),
    '7719': (accountPattern: r'^\d{12}$', branchRequired: true, name: 'National Savings Bank', shortName: 'NSB'),
    '7162': (accountPattern: r'^\d{12}$', branchRequired: false, name: 'Nations Trust Bank', shortName: 'NTB'),
    '7454': (accountPattern: r'^\d{12}$', branchRequired: false, name: 'DFCC Bank', shortName: 'DFCC'),
    '7311': (accountPattern: r'^\d{12}$', branchRequired: false, name: 'Pan Asia Bank', shortName: 'Pan Asia'),
  };

  static const Map<String, List<({String code, String name})>> branches = {
    '7135': [(code: '001', name: 'Colombo 01'), (code: '024', name: 'Kandy'), (code: '052', name: 'Galle'), (code: '118', name: 'Jaffna'), (code: '231', name: 'Kurunegala')],
    '7719': [(code: '001', name: 'Head Office'), (code: '010', name: 'Nugegoda'), (code: '035', name: 'Matara'), (code: '062', name: 'Batticaloa')],
  };

  final DateTime Function() _clock;

  final MockAuthenticator _authenticator;

  final MockCheckout _checkout;

  final MockStore _store;

  BanksMockModule(this._authenticator, this._checkout, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static String bankAccount(String bankCode, String accountNumber) => 'bank:$bankCode:$accountNumber';

  static ({String? holder, MockResponse? rejection}) resolve(Object? bankCode, Object? branchCode, Object? accountNumber) {
    final bank = bankCode is String ? directory[bankCode] : null;
    if (bank == null) return (holder: null, rejection: MockResponse.error(404, FailureCodes.bankNotFound));
    final hasBranch = branchCode is String && (branches[bankCode]?.any((branch) => branch.code == branchCode) ?? false);
    if (bank.branchRequired && !hasBranch) return (holder: null, rejection: MockResponse.error(400, FailureCodes.invalidRequest, field: 'branchCode'));
    if (accountNumber is! String || !RegExp(bank.accountPattern).hasMatch(accountNumber)) return (holder: null, rejection: MockResponse.error(400, FailureCodes.invalidAccountNumber, field: 'accountNumber'));
    if (accountNumber.endsWith(unknownAccountSuffix)) return (holder: null, rejection: MockResponse.error(404, FailureCodes.bankAccountNotFound));
    final hash = '$bankCode$accountNumber'.codeUnits.fold(_hashSeed, (value, unit) => (value * _hashStep + unit) % _hashModulus);
    return (holder: _holders[hash % _holders.length], rejection: null);
  }

  Future<MockResponse> _banks(MockRequest request) => _authenticator.guard(
    request,
    (principal) async => MockResponse.ok({
      'items': [for (final code in directory.keys) _bankJson(code)],
    }),
  );

  Future<MockResponse> _branches(MockRequest request) => _authenticator.guard(request, (principal) async {
    final code = request.params['id'];
    if (!directory.containsKey(code)) return MockResponse.error(404, FailureCodes.bankNotFound);
    return MockResponse.ok({
      'items': [
        for (final branch in branches[code] ?? const <({String code, String name})>[]) {'code': branch.code, 'name': branch.name},
      ],
    });
  });

  Future<MockResponse> _lookup(MockRequest request) => _authenticator.guard(request, (principal) async {
    final (:holder, :rejection) = resolve(request.body['bankCode'], request.body['branchCode'], request.body['accountNumber']);
    if (holder == null) return rejection!;
    return MockResponse.ok({'accountName': holder, 'accountNumber': request.body['accountNumber'], 'bank': _bankJson(request.body['bankCode'] as String), 'branchCode': request.body['branchCode']});
  });

  Future<MockResponse> _transfer(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final note = request.body['note'];
    final invalid = MockRules.rejectKey(request) ?? MockRules.rejectAmount(amountCents) ?? MockRules.rejectNote(note);
    if (invalid != null) return invalid;
    final bankCode = request.body['bankCode'];
    final branchCode = request.body['branchCode'];
    final accountNumber = request.body['accountNumber'];
    final (:holder, :rejection) = resolve(bankCode, branchCode, accountNumber);
    if (holder == null) return rejection!;
    final charge = await _checkout.charge(
      principal,
      amountCents: amountCents as int,
      approval: request.body['approval'],
      approvalPayload: ApprovalPayload.bankTransfer(accountNumber: accountNumber as String, amountCents: amountCents, bankCode: bankCode as String, idempotencyKey: request.header(ApiHeaders.idempotencyKey)!),
      creditAccount: bankAccount(bankCode, accountNumber),
      creditName: holder,
      feeCents: feeCents,
      meta: {'accountName': holder, 'accountNumber': accountNumber, 'bankCode': bankCode, 'branchCode': branchCode, 'kind': kind},
      note: note as String?,
      type: transactionType,
    );
    final transaction = charge.transaction;
    if (transaction == null) return charge.rejection!;
    return MockResponse.created(MockRules.receipt(transaction, extra: {'accountName': holder, 'accountNumber': accountNumber, 'bank': _bankJson(bankCode)}));
  });

  Future<MockResponse> _payees(MockRequest request) => _authenticator.guard(
    request,
    (principal) async => MockResponse.ok({
      'items': [for (final payee in _payeesOf(principal)) _payeeJson(payee)],
    }),
  );

  Future<MockResponse> _savePayee(MockRequest request) => _authenticator.guard(request, (principal) async {
    final bankCode = request.body['bankCode'];
    final branchCode = request.body['branchCode'];
    final accountNumber = request.body['accountNumber'];
    final nickname = request.body['nickname'] ?? '';
    if (nickname is! String || nickname.trim().length > maxNicknameLength) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'nickname');
    final (:holder, :rejection) = resolve(bankCode, branchCode, accountNumber);
    if (holder == null) return rejection!;
    if (_payeesOf(principal).any((payee) => payee['bankCode'] == bankCode && payee['accountNumber'] == accountNumber)) return MockResponse.error(409, FailureCodes.bankPayeeExists);
    final id = IdGenerator.next();
    final payee = {'accountName': holder, 'accountNumber': accountNumber, 'bankCode': bankCode, 'branchCode': branchCode, 'id': id, 'nickname': nickname.trim(), 'userId': principal.userId, 'createdAt': _clock().toUtc().toIso8601String()};
    await _store.put(MockCollections.bankPayees, id, payee);
    return MockResponse.created(_payeeJson(payee));
  });

  Future<MockResponse> _deletePayee(MockRequest request) => _authenticator.guard(request, (principal) async {
    final id = request.params['id'];
    final payee = id == null ? null : _store.find(MockCollections.bankPayees, id);
    if (id == null || payee == null || payee['userId'] != principal.userId) return MockResponse.error(404, FailureCodes.notFound);
    await _store.remove(MockCollections.bankPayees, id);
    return const MockResponse.noContent();
  });

  List<Map<String, dynamic>> _payeesOf(MockPrincipal principal) =>
      _store.all(MockCollections.bankPayees).where((payee) => payee['userId'] == principal.userId).toList()..sort((first, second) => (first['createdAt'] as String).compareTo(second['createdAt'] as String));

  Map<String, dynamic> _payeeJson(Map<String, dynamic> payee) => {
    'accountName': payee['accountName'],
    'accountNumber': payee['accountNumber'],
    'bank': _bankJson(payee['bankCode'] as String),
    'branchCode': payee['branchCode'],
    'id': payee['id'],
    'nickname': payee['nickname'],
  };

  Map<String, dynamic> _bankJson(String code) {
    final bank = directory[code]!;
    return {'accountPattern': bank.accountPattern, 'branchRequired': bank.branchRequired, 'code': code, 'feeCents': feeCents, 'name': bank.name, 'shortName': bank.shortName};
  }

  @override
  List<MockRoute> get routes => [
    MockRoute.get(ApiPaths.banks, _banks),
    MockRoute.get(ApiPaths.bankBranches, _branches),
    MockRoute.post(ApiPaths.bankAccountLookup, _lookup),
    MockRoute.post(ApiPaths.bankTransfers, _transfer),
    MockRoute.get(ApiPaths.bankPayees, _payees),
    MockRoute.post(ApiPaths.bankPayees, _savePayee),
    MockRoute.delete(ApiPaths.bankPayee, _deletePayee),
  ];
}
