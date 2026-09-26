import 'dart:math';

import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../../utils/id_generator.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_ledger.dart';
import '../mock_module.dart';
import '../mock_principal.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_store.dart';
import '../mock_wallet_seeder.dart';
import 'banks_mock_module.dart';
import 'bills_mock_module.dart';
import 'merchants_mock_module.dart';

class WalletMockModule implements MockModule {
  static const int defaultPageSize = 20;
  static const int maxDetailsLength = 280;
  static const int maxPageSize = 50;
  static const int _referenceDigits = 8;

  static const String currency = 'LKR';
  static const String _disputePrefix = 'DSP';
  static const String transferIn = 'transfer_in';
  static const String transferOut = 'transfer_out';

  static const Map<String, String> _categoryByType = {'bank_transfer': 'transfers', 'bill': 'bills', 'card': 'online', 'fee': 'fees', 'reload': 'reload', transferOut: 'transfers'};

  static const Set<String> disputeReasons = {'duplicate', 'not_received', 'other', 'unauthorized', 'wrong_amount'};
  static const Set<String> _incomeTypes = {'bonus', 'cashback', transferIn};

  static const Duration _settlementDelay = Duration(seconds: 2);

  final DateTime Function() _clock;

  final MockAuthenticator _authenticator;

  final MockLedger _ledger;

  final MockStore _store;

  final MockWalletSeeder _seeder;

  final Random _random = Random.secure();

  WalletMockModule(this._authenticator, this._ledger, this._store, this._seeder, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static Map<String, dynamic> view(Map<String, dynamic> transaction, String account) {
    final isCredit = transaction['creditAccount'] == account;
    final amountCents = transaction['amountCents'] as int;
    final type = transaction['type'] as String;
    return {
      'amountCents': isCredit ? amountCents : -amountCents,
      'counterpartyName': transaction[isCredit ? 'debitName' : 'creditName'],
      'counterpartyPhone': transaction[isCredit ? 'debitPhone' : 'creditPhone'],
      'id': transaction['id'],
      'note': transaction['note'],
      'reference': transaction['reference'],
      'status': transaction['status'],
      'type': type == MockWalletSeeder.transfer ? (isCredit ? transferIn : transferOut) : type,
      'createdAt': transaction['createdAt'],
    };
  }

  static String? insightCategory(Map<String, dynamic> view, Map<String, dynamic>? meta) {
    final type = view['type'] as String;
    if ((view['amountCents'] as int) > 0) return null;
    if (type == MerchantsMockModule.transactionType) return meta?['category'] as String? ?? 'shopping';
    return _categoryByType[type];
  }

  Future<MockResponse> _wallet(MockRequest request) => _authenticator.guard(request, (principal) async {
    await _seeder.ensureSeeded(principal.userId);
    return MockResponse.ok({'balanceCents': _ledger.balanceOf(MockWalletSeeder.walletAccount(principal.userId)), 'currency': currency});
  });

  Future<MockResponse> _transactions(MockRequest request) => _authenticator.guard(request, (principal) async {
    await _seeder.ensureSeeded(principal.userId);
    final account = MockWalletSeeder.walletAccount(principal.userId);
    final limit = (int.tryParse('${request.query['limit'] ?? ''}') ?? defaultPageSize).clamp(1, maxPageSize);
    final cursor = request.query['cursor'];
    final all = [for (final transaction in _ledger.transactionsFor(account)) view(transaction, account)].where((view) => _matches(view, request.query)).toList();
    final cursorIndex = cursor == null ? -1 : all.indexWhere((transaction) => transaction['id'] == cursor);
    if (cursor != null && cursorIndex < 0) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'cursor');
    final page = all.skip(cursorIndex + 1).take(limit).toList();
    final hasMore = cursorIndex + 1 + page.length < all.length;
    return MockResponse.ok({'items': page, 'nextCursor': hasMore ? page.last['id'] : null});
  });

  Future<MockResponse> _transaction(MockRequest request) => _authenticator.guard(request, (principal) async {
    final transaction = _own(principal, request.params['id']);
    if (transaction == null) return MockResponse.error(404, FailureCodes.notFound);
    final account = MockWalletSeeder.walletAccount(principal.userId);
    final createdAt = DateTime.parse(transaction['createdAt'] as String);
    final dispute = _store.all(MockCollections.disputes).where((dispute) => dispute['transactionId'] == transaction['id']).firstOrNull;
    return MockResponse.ok({
      ...view(transaction, account),
      'dispute': dispute == null ? null : _disputeJson(dispute),
      'feeCents': transaction['feeCents'] ?? 0,
      'repeat': transaction['debitAccount'] == account ? _repeat(transaction) : null,
      'timeline': [
        {'at': createdAt.toIso8601String(), 'status': 'initiated'},
        {'at': createdAt.add(_settlementDelay).toIso8601String(), 'status': transaction['status']},
      ],
    });
  });

  Future<MockResponse> _dispute(MockRequest request) => _authenticator.guard(request, (principal) async {
    final transaction = _own(principal, request.params['id']);
    if (transaction == null) return MockResponse.error(404, FailureCodes.notFound);
    final reason = request.body['reason'];
    final details = request.body['details'];
    if (reason is! String || !disputeReasons.contains(reason)) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'reason');
    if (details != null && (details is! String || details.length > maxDetailsLength)) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'details');
    if (_store.all(MockCollections.disputes).any((dispute) => dispute['transactionId'] == transaction['id'])) return MockResponse.error(409, FailureCodes.disputeExists);
    final id = IdGenerator.next();
    final dispute = {
      'details': details,
      'id': id,
      'reason': reason,
      'reference': '$_disputePrefix${[for (var index = 0; index < _referenceDigits; index++) _random.nextInt(10)].join()}',
      'status': 'open',
      'transactionId': transaction['id'],
      'userId': principal.userId,
      'createdAt': _clock().toUtc().toIso8601String(),
    };
    await _store.put(MockCollections.disputes, id, dispute);
    return MockResponse.created(_disputeJson(dispute));
  });

  Future<MockResponse> _insights(MockRequest request) => _authenticator.guard(request, (principal) async {
    await _seeder.ensureSeeded(principal.userId);
    final month = DateTime.tryParse('${request.query['month'] ?? ''}-01');
    if (month == null) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'month');
    final account = MockWalletSeeder.walletAccount(principal.userId);
    final (:income, :spending, :categories) = _summarise(account, DateTime.utc(month.year, month.month), DateTime.utc(month.year, month.month + 1));
    final previous = _summarise(account, DateTime.utc(month.year, month.month - 1), DateTime.utc(month.year, month.month));
    return MockResponse.ok({
      'categories': [
        for (final entry in categories.entries.toList()..sort((first, second) => second.value.amountCents.compareTo(first.value.amountCents))) {'amountCents': entry.value.amountCents, 'category': entry.key, 'count': entry.value.count},
      ],
      'incomeCents': income,
      'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'previousSpendingCents': previous.spending,
      'spendingCents': spending,
    });
  });

  bool _matches(Map<String, dynamic> view, Map<String, dynamic> query) {
    final types = '${query['type'] ?? ''}'.split(',').where((type) => type.isNotEmpty).toSet();
    final from = DateTime.tryParse('${query['from'] ?? ''}');
    final to = DateTime.tryParse('${query['to'] ?? ''}');
    final minCents = int.tryParse('${query['minCents'] ?? ''}');
    final maxCents = int.tryParse('${query['maxCents'] ?? ''}');
    final search = '${query['q'] ?? ''}'.trim().toLowerCase();
    final createdAt = DateTime.parse(view['createdAt'] as String);
    final amount = (view['amountCents'] as int).abs();
    return (types.isEmpty || types.contains(view['type'])) &&
        (from == null || !createdAt.isBefore(from)) &&
        (to == null || createdAt.isBefore(to)) &&
        (minCents == null || amount >= minCents) &&
        (maxCents == null || amount <= maxCents) &&
        (search.isEmpty || [view['counterpartyName'], view['note'], view['reference']].any((field) => field is String && field.toLowerCase().contains(search)));
  }

  Map<String, dynamic>? _own(MockPrincipal principal, Object? id) {
    final transaction = id is String ? _store.find(MockCollections.ledgerTransactions, id) : null;
    final account = MockWalletSeeder.walletAccount(principal.userId);
    return transaction != null && (transaction['debitAccount'] == account || transaction['creditAccount'] == account) ? transaction : null;
  }

  Map<String, dynamic> _disputeJson(Map<String, dynamic> dispute) => {'id': dispute['id'], 'reason': dispute['reason'], 'reference': dispute['reference'], 'status': dispute['status'], 'createdAt': dispute['createdAt']};

  Map<String, dynamic>? _repeat(Map<String, dynamic> transaction) {
    final meta = transaction['meta'] as Map<String, dynamic>? ?? const {};
    final name = transaction['creditName'] as String;
    return switch (meta['kind']) {
      MockWalletSeeder.transfer when meta['phone'] != null => {'kind': 'transfer', 'name': name, 'phone': meta['phone']},
      MerchantsMockModule.transactionType when meta['qr'] != null => {
        'kind': 'merchant',
        'merchant': {'category': meta['category'], 'city': MerchantsMockModule.directory[meta['merchantId']]?.city ?? '', 'id': meta['merchantId'], 'name': name},
        'qr': meta['qr'],
      },
      BillsMockModule.transactionType when meta['accountNumber'] != null => {'accountNumber': meta['accountNumber'], 'billerId': meta['billerId'], 'billerName': name, 'category': meta['category'], 'kind': 'bill'},
      'reload' when meta['phone'] != null => {'kind': 'reload', 'phone': meta['phone']},
      BanksMockModule.kind when meta['bankCode'] != null => {
        'accountName': meta['accountName'],
        'accountNumber': meta['accountNumber'],
        'bankCode': meta['bankCode'],
        'bankName': BanksMockModule.directory[meta['bankCode']]?.name,
        'bankShortName': BanksMockModule.directory[meta['bankCode']]?.shortName,
        'branchCode': meta['branchCode'],
        'feeCents': BanksMockModule.feeCents,
        'kind': 'bank',
      },
      _ => null,
    };
  }

  ({Map<String, ({int amountCents, int count})> categories, int income, int spending}) _summarise(String account, DateTime from, DateTime to) {
    var income = 0;
    var spending = 0;
    final categories = <String, ({int amountCents, int count})>{};
    for (final transaction in _ledger.transactionsFor(account)) {
      final createdAt = DateTime.parse(transaction['createdAt'] as String);
      if (createdAt.isBefore(from) || !createdAt.isBefore(to)) continue;
      final entry = view(transaction, account);
      final amount = entry['amountCents'] as int;
      if (amount > 0) {
        if (_incomeTypes.contains(entry['type'])) income += amount;
        continue;
      }
      final category = insightCategory(entry, transaction['meta'] as Map<String, dynamic>?);
      if (category == null) continue;
      spending += -amount;
      final current = categories[category];
      categories[category] = (amountCents: (current?.amountCents ?? 0) - amount, count: (current?.count ?? 0) + 1);
    }
    return (categories: categories, income: income, spending: spending);
  }

  @override
  List<MockRoute> get routes => [
    MockRoute.get(ApiPaths.wallet, _wallet),
    MockRoute.get(ApiPaths.transactions, _transactions),
    MockRoute.get(ApiPaths.transaction, _transaction),
    MockRoute.post(ApiPaths.transactionDisputes, _dispute),
    MockRoute.get(ApiPaths.insights, _insights),
  ];
}
