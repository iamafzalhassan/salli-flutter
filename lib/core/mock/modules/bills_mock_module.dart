import 'dart:math';

import '../../errors/failure_codes.dart';
import '../../network/api_headers.dart';
import '../../network/api_paths.dart';
import '../../security/approval_payload.dart';
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
import '../mock_rules.dart';
import '../mock_store.dart';

class BillsMockModule implements MockModule {
  static const int _dueSpreadDays = 20;
  static const int _hashModulus = 1000003;
  static const int _hashSeed = 7;
  static const int _hashStep = 31;
  static const int lastScheduleDay = 28;
  static const int maxNicknameLength = 30;
  static const int maxSavedBillers = 20;
  static const int _minDueDays = 3;
  static const int _runHourUtc = 3;
  static const int _runMinuteUtc = 30;

  static const String failedRun = 'failed';
  static const String nothingDueRun = 'nothing_due';
  static const String paidRun = 'paid';
  static const String transactionType = 'bill';
  static const String unknownAccountSuffix = '0000';

  static const List<String> _customers = ['A. M. Perera', 'S. Fernando', 'R. Jayasinghe', 'N. Rajapaksha', 'K. Wickramasinghe', 'F. Rizna', 'T. Sivakumar', 'M. Nazeer'];

  static const Map<String, ({int maxCents, int minCents})> _ranges = {
    'electricity': (maxCents: 900000, minCents: 150000),
    'insurance': (maxCents: 2500000, minCents: 500000),
    'leasing': (maxCents: 6000000, minCents: 1500000),
    'telecom': (maxCents: 600000, minCents: 80000),
    'television': (maxCents: 350000, minCents: 100000),
    'water': (maxCents: 350000, minCents: 50000),
  };

  static const Map<String, ({String accountHint, String accountKind, String accountPattern, String category, String name})> directory = {
    'ceb': (accountHint: '0123456789', accountKind: 'account', accountPattern: r'^\d{10}$', category: 'electricity', name: 'Ceylon Electricity Board'),
    'leco': (accountHint: '1234567890', accountKind: 'account', accountPattern: r'^\d{10}$', category: 'electricity', name: 'LECO'),
    'nwsdb': (accountHint: '102512345607', accountKind: 'account', accountPattern: r'^\d{12}$', category: 'water', name: 'National Water Supply & Drainage Board'),
    'slt': (accountHint: '0112345678', accountKind: 'phone', accountPattern: r'^0\d{9}$', category: 'telecom', name: 'SLT-Mobitel'),
    'dialog': (accountHint: '0771234567', accountKind: 'phone', accountPattern: r'^0\d{9}$', category: 'telecom', name: 'Dialog Axiata'),
    'hutch': (accountHint: '0781234567', accountKind: 'phone', accountPattern: r'^0\d{9}$', category: 'telecom', name: 'Hutch'),
    'airtel': (accountHint: '0751234567', accountKind: 'phone', accountPattern: r'^0\d{9}$', category: 'telecom', name: 'Airtel'),
    'dialog_tv': (accountHint: '12345678', accountKind: 'subscriber', accountPattern: r'^\d{8}$', category: 'television', name: 'Dialog Television'),
    'peo_tv': (accountHint: '0112345678', accountKind: 'phone', accountPattern: r'^0\d{9}$', category: 'television', name: 'PEO TV'),
    'ceylinco_life': (accountHint: 'LP12345678', accountKind: 'policy', accountPattern: r'^[A-Z]{2}\d{8}$', category: 'insurance', name: 'Ceylinco Life'),
    'slic': (accountHint: 'MV23456789', accountKind: 'policy', accountPattern: r'^[A-Z]{2}\d{8}$', category: 'insurance', name: 'Sri Lanka Insurance'),
    'lb_finance': (accountHint: 'LBF1234567', accountKind: 'contract', accountPattern: r'^[A-Z]{3}\d{7}$', category: 'leasing', name: 'LB Finance'),
    'cdb': (accountHint: 'CDB7654321', accountKind: 'contract', accountPattern: r'^[A-Z]{3}\d{7}$', category: 'leasing', name: 'Citizens Development Business Finance'),
  };

  static const Duration cycle = Duration(days: 30);

  final DateTime Function() _clock;

  final MockApprovalVerifier _approvalVerifier;

  final MockAuthenticator _authenticator;

  final MockCheckout _checkout;

  final MockLedger _ledger;

  final MockStore _store;

  BillsMockModule(this._approvalVerifier, this._authenticator, this._checkout, this._ledger, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static String billerAccount(String billerId) => 'biller:$billerId';

  Future<MockResponse> _billers(MockRequest request) => _authenticator.guard(
    request,
    (principal) async => MockResponse.ok({
      'items': [for (final id in directory.keys) _billerJson(id)],
    }),
  );

  Future<MockResponse> _inquire(MockRequest request) => _authenticator.guard(request, (principal) async {
    final billerId = request.body['billerId'];
    final accountNumber = request.body['accountNumber'];
    final invalid = _rejectAccount(billerId, accountNumber);
    if (invalid != null) return invalid;
    final bill = _bill(billerId as String, accountNumber as String);
    if (bill == null) return MockResponse.error(404, FailureCodes.billAccountNotFound);
    return MockResponse.ok(bill);
  });

  Future<MockResponse> _pay(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final note = request.body['note'];
    final billerId = request.body['billerId'];
    final accountNumber = request.body['accountNumber'];
    final invalid = MockRules.rejectKey(request) ?? MockRules.rejectAmount(amountCents) ?? MockRules.rejectNote(note) ?? _rejectAccount(billerId, accountNumber);
    if (invalid != null) return invalid;
    if (_bill(billerId as String, accountNumber as String) == null) return MockResponse.error(404, FailureCodes.billAccountNotFound);
    final biller = directory[billerId]!;
    final charge = await _checkout.charge(
      principal,
      amountCents: amountCents as int,
      approval: request.body['approval'],
      approvalPayload: ApprovalPayload.billPayment(accountNumber: accountNumber, amountCents: amountCents, billerId: billerId, idempotencyKey: request.header(ApiHeaders.idempotencyKey)!),
      creditAccount: billerAccount(billerId),
      creditName: biller.name,
      meta: {'accountNumber': accountNumber, 'billerId': billerId, 'category': biller.category, 'kind': transactionType},
      note: note as String?,
      type: transactionType,
    );
    final transaction = charge.transaction;
    if (transaction == null) return charge.rejection!;
    return MockResponse.created(MockRules.receipt(transaction, extra: {'accountNumber': accountNumber, 'biller': _billerJson(billerId)}));
  });

  Future<MockResponse> _saved(MockRequest request) => _authenticator.guard(
    request,
    (principal) async => MockResponse.ok({
      'items': [for (final saved in _savedOf(principal)) _savedJson(saved)],
    }),
  );

  Future<MockResponse> _save(MockRequest request) => _authenticator.guard(request, (principal) async {
    final billerId = request.body['billerId'];
    final accountNumber = request.body['accountNumber'];
    final nickname = request.body['nickname'] ?? '';
    final invalid = _rejectAccount(billerId, accountNumber) ?? _rejectNickname(nickname);
    if (invalid != null) return invalid;
    final saved = _savedOf(principal);
    if (saved.any((entry) => entry['billerId'] == billerId && entry['accountNumber'] == accountNumber)) return MockResponse.error(409, FailureCodes.savedBillerExists);
    if (saved.length >= maxSavedBillers) return MockResponse.error(422, FailureCodes.invalidRequest);
    final id = IdGenerator.next();
    final entry = {'accountNumber': accountNumber, 'billerId': billerId, 'id': id, 'nickname': (nickname as String).trim(), 'userId': principal.userId, 'createdAt': _clock().toUtc().toIso8601String()};
    await _store.put(MockCollections.savedBillers, id, entry);
    return MockResponse.created(_savedJson(entry));
  });

  Future<MockResponse> _rename(MockRequest request) => _authenticator.guard(request, (principal) async {
    final saved = _ownSaved(principal, request.params['id']);
    if (saved == null) return MockResponse.error(404, FailureCodes.notFound);
    final nickname = request.body['nickname'];
    final invalid = _rejectNickname(nickname);
    if (invalid != null) return invalid;
    final updated = {...saved, 'nickname': (nickname as String).trim()};
    await _store.put(MockCollections.savedBillers, saved['id'] as String, updated);
    return MockResponse.ok(_savedJson(updated));
  });

  Future<MockResponse> _unsave(MockRequest request) => _authenticator.guard(request, (principal) async {
    final saved = _ownSaved(principal, request.params['id']);
    if (saved == null) return MockResponse.error(404, FailureCodes.notFound);
    for (final schedule in _store.entries(MockCollections.billSchedules).where((entry) => entry.value['savedBillerId'] == saved['id'])) {
      await _store.remove(MockCollections.billSchedules, schedule.key);
    }
    await _store.remove(MockCollections.savedBillers, saved['id'] as String);
    return const MockResponse.noContent();
  });

  Future<MockResponse> _schedules(MockRequest request) => _authenticator.guard(request, (principal) async {
    final now = _clock().toUtc();
    final items = <Map<String, dynamic>>[];
    for (final schedule in _store.all(MockCollections.billSchedules).where((schedule) => schedule['userId'] == principal.userId)) {
      final saved = _store.find(MockCollections.savedBillers, schedule['savedBillerId'] as String);
      if (saved == null) continue;
      final current = schedule['autopay'] == true ? await _runIfDue(principal, schedule, saved, now) : schedule;
      items.add(_scheduleJson(current, saved, now));
    }
    items.sort((first, second) => (first['nextRunAt'] as String).compareTo(second['nextRunAt'] as String));
    return MockResponse.ok({'items': items});
  });

  Future<MockResponse> _schedule(MockRequest request) => _authenticator.guard(request, (principal) async {
    final saved = _ownSaved(principal, request.body['savedBillerId']);
    if (saved == null) return MockResponse.error(404, FailureCodes.notFound);
    final dayOfMonth = request.body['dayOfMonth'];
    if (dayOfMonth is! int || dayOfMonth < 1 || dayOfMonth > lastScheduleDay) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'dayOfMonth');
    final autopay = request.body['autopay'] == true;
    if (_store.all(MockCollections.billSchedules).any((schedule) => schedule['savedBillerId'] == saved['id'])) return MockResponse.error(409, FailureCodes.scheduleExists);
    if (autopay) {
      final invalid = MockRules.rejectKey(request);
      if (invalid != null) return invalid;
      final payload = ApprovalPayload.billMandate(dayOfMonth: dayOfMonth, idempotencyKey: request.header(ApiHeaders.idempotencyKey)!, savedBillerId: saved['id'] as String);
      final rejection = await _approvalVerifier.verify(principal, request.body['approval'], payload);
      if (rejection != null) return rejection;
    }
    final now = _clock().toUtc();
    final id = IdGenerator.next();
    final schedule = {'autopay': autopay, 'dayOfMonth': dayOfMonth, 'id': id, 'lastRunAt': null, 'lastStatus': null, 'savedBillerId': saved['id'], 'userId': principal.userId, 'createdAt': now.toIso8601String()};
    await _store.put(MockCollections.billSchedules, id, schedule);
    return MockResponse.created(_scheduleJson(schedule, saved, now));
  });

  Future<MockResponse> _unschedule(MockRequest request) => _authenticator.guard(request, (principal) async {
    final id = request.params['id'];
    final schedule = id == null ? null : _store.find(MockCollections.billSchedules, id);
    if (schedule == null || schedule['userId'] != principal.userId) return MockResponse.error(404, FailureCodes.notFound);
    await _store.remove(MockCollections.billSchedules, id!);
    return const MockResponse.noContent();
  });

  MockResponse? _rejectAccount(Object? billerId, Object? accountNumber) {
    final biller = billerId is String ? directory[billerId] : null;
    if (biller == null) return MockResponse.error(404, FailureCodes.billerNotFound);
    if (accountNumber is! String || !RegExp(biller.accountPattern).hasMatch(accountNumber)) return MockResponse.error(400, FailureCodes.invalidAccountNumber, field: 'accountNumber');
    return null;
  }

  MockResponse? _rejectNickname(Object? nickname) => nickname is! String || nickname.trim().length > maxNicknameLength ? MockResponse.error(400, FailureCodes.invalidRequest, field: 'nickname') : null;

  List<Map<String, dynamic>> _savedOf(MockPrincipal principal) =>
      _store.all(MockCollections.savedBillers).where((saved) => saved['userId'] == principal.userId).toList()..sort((first, second) => (first['createdAt'] as String).compareTo(second['createdAt'] as String));

  Map<String, dynamic>? _ownSaved(MockPrincipal principal, Object? id) {
    final saved = id is String ? _store.find(MockCollections.savedBillers, id) : null;
    return saved != null && saved['userId'] == principal.userId ? saved : null;
  }

  Future<Map<String, dynamic>> _runIfDue(MockPrincipal principal, Map<String, dynamic> schedule, Map<String, dynamic> saved, DateTime now) async {
    final runAt = _runAt(schedule['dayOfMonth'] as int, now.year, now.month);
    final lastRunAt = schedule['lastRunAt'] as String?;
    final isDue = !runAt.isAfter(now) && DateTime.parse(schedule['createdAt'] as String).isBefore(runAt) && (lastRunAt == null || DateTime.parse(lastRunAt).isBefore(runAt));
    if (!isDue) return schedule;
    final billerId = saved['billerId'] as String;
    final accountNumber = saved['accountNumber'] as String;
    final amountDueCents = _bill(billerId, accountNumber)?['amountDueCents'] as int? ?? 0;
    var status = nothingDueRun;
    if (amountDueCents > 0) {
      final biller = directory[billerId]!;
      final charge = await _checkout.charge(
        principal,
        amountCents: amountDueCents,
        creditAccount: billerAccount(billerId),
        creditName: biller.name,
        isPreApproved: true,
        meta: {'accountNumber': accountNumber, 'billerId': billerId, 'category': biller.category, 'kind': transactionType},
        type: transactionType,
      );
      status = charge.transaction == null ? failedRun : paidRun;
    }
    final updated = {...schedule, 'lastRunAt': now.toIso8601String(), 'lastStatus': status};
    await _store.put(MockCollections.billSchedules, schedule['id'] as String, updated);
    return updated;
  }

  Map<String, dynamic> _scheduleJson(Map<String, dynamic> schedule, Map<String, dynamic> saved, DateTime now) {
    final day = schedule['dayOfMonth'] as int;
    final thisMonth = _runAt(day, now.year, now.month);
    final lastRunAt = schedule['lastRunAt'] as String?;
    final hasRun = lastRunAt != null && !DateTime.parse(lastRunAt).isBefore(thisMonth);
    final nextRunAt = thisMonth.isAfter(now) || (!hasRun && schedule['autopay'] != true) ? thisMonth : _runAt(day, now.year, now.month + 1);
    return {
      'amountDueCents': _bill(saved['billerId'] as String, saved['accountNumber'] as String)?['amountDueCents'],
      'autopay': schedule['autopay'],
      'dayOfMonth': day,
      'id': schedule['id'],
      'lastRunAt': lastRunAt,
      'lastStatus': schedule['lastStatus'],
      'nextRunAt': nextRunAt.toIso8601String(),
      'savedBiller': _savedJson(saved),
    };
  }

  Map<String, dynamic> _savedJson(Map<String, dynamic> saved) => {'accountNumber': saved['accountNumber'], 'biller': _billerJson(saved['billerId'] as String), 'id': saved['id'], 'nickname': saved['nickname']};

  Map<String, dynamic>? _bill(String billerId, String accountNumber) {
    if (accountNumber.endsWith(unknownAccountSuffix)) return null;
    final biller = directory[billerId]!;
    final hash = accountNumber.codeUnits.fold(_hashSeed, (value, unit) => (value * _hashStep + unit) % _hashModulus);
    final range = _ranges[biller.category]!;
    final now = _clock().toUtc();
    final paidCents = _ledger
        .transactionsFor(billerAccount(billerId))
        .where((transaction) => (transaction['meta'] as Map<String, dynamic>?)?['accountNumber'] == accountNumber && !DateTime.parse(transaction['createdAt'] as String).isBefore(now.subtract(cycle)))
        .fold(0, (sum, transaction) => sum + (transaction['amountCents'] as int));
    return {
      'accountNumber': accountNumber,
      'amountDueCents': max(0, range.minCents + hash % (range.maxCents - range.minCents) - paidCents),
      'biller': _billerJson(billerId),
      'customerName': _customers[hash % _customers.length],
      'dueDate': DateTime.utc(now.year, now.month, now.day).add(Duration(days: _minDueDays + hash % _dueSpreadDays)).toIso8601String(),
    };
  }

  Map<String, dynamic> _billerJson(String id) {
    final biller = directory[id]!;
    return {'accountHint': biller.accountHint, 'accountKind': biller.accountKind, 'accountPattern': biller.accountPattern, 'category': biller.category, 'id': id, 'name': biller.name};
  }

  DateTime _runAt(int day, int year, int month) => DateTime.utc(year, month, day, _runHourUtc, _runMinuteUtc);

  @override
  List<MockRoute> get routes => [
    MockRoute.get(ApiPaths.billers, _billers),
    MockRoute.post(ApiPaths.billInquiry, _inquire),
    MockRoute.post(ApiPaths.billPayments, _pay),
    MockRoute.get(ApiPaths.savedBillers, _saved),
    MockRoute.post(ApiPaths.savedBillers, _save),
    MockRoute.patch(ApiPaths.savedBiller, _rename),
    MockRoute.delete(ApiPaths.savedBiller, _unsave),
    MockRoute.get(ApiPaths.billSchedules, _schedules),
    MockRoute.post(ApiPaths.billSchedules, _schedule),
    MockRoute.delete(ApiPaths.billSchedule, _unschedule),
  ];
}
