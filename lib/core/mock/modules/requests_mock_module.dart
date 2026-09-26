import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../../utils/id_generator.dart';
import '../../utils/money.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_ledger.dart';
import '../mock_module.dart';
import '../mock_notifier.dart';
import '../mock_principal.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_rules.dart';
import '../mock_store.dart';
import '../mock_wallet_seeder.dart';
import 'payments_mock_module.dart';

class RequestsMockModule implements MockModule {
  static const int maxAmountCents = 20000000;
  static const int maxParticipants = 10;

  static const String cancelled = 'cancelled';
  static const String declined = 'declined';
  static const String incoming = 'incoming';
  static const String outgoing = 'outgoing';
  static const String paid = 'paid';
  static const String pending = 'pending';

  static const ({int amountCents, String note, String phone}) seedRequest = (amountCents: 125000, note: 'Kottu night', phone: '+94712223344');

  static const Duration directoryReplyDelay = Duration(minutes: 2);
  static const Duration remindInterval = Duration(days: 1);
  static const Duration _seedAge = Duration(hours: 2);

  final DateTime Function() _clock;

  final MockAuthenticator _authenticator;

  final MockLedger _ledger;

  final MockNotifier _notifier;

  final MockStore _store;

  RequestsMockModule(this._authenticator, this._ledger, this._notifier, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<MockResponse> _list(MockRequest request) => _authenticator.guard(request, (principal) async {
    await _prepare(principal);
    final phone = _phoneOf(principal);
    final items = _store.all(MockCollections.moneyRequests).where((entry) => entry['fromUserId'] == principal.userId || entry['toPhone'] == phone).toList()
      ..sort((first, second) => (second['createdAt'] as String).compareTo(first['createdAt'] as String));
    return MockResponse.ok({
      'items': [for (final entry in items) _view(entry, principal)],
    });
  });

  Future<MockResponse> _create(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final note = request.body['note'];
    final invalid = _rejectAmount(amountCents) ?? MockRules.rejectNote(note);
    if (invalid != null) return invalid;
    final phone = request.body['phone'];
    if (phone is! String || !MockRules.phonePattern.hasMatch(phone)) return MockResponse.error(400, FailureCodes.invalidPhone, field: 'phone');
    if (phone == _phoneOf(principal)) return MockResponse.error(422, FailureCodes.cannotRequestSelf);
    if (PaymentsMockModule.resolve(_store, phone) == null) return MockResponse.error(404, FailureCodes.payeeNotFound);
    final entry = await _open(principal, amountCents as int, note as String?, phone);
    return MockResponse.created(_view(entry, principal));
  });

  Future<MockResponse> _decline(MockRequest request) => _transition(request, incoming, declined);

  Future<MockResponse> _cancel(MockRequest request) => _transition(request, outgoing, cancelled);

  Future<MockResponse> _remind(MockRequest request) => _authenticator.guard(request, (principal) async {
    final entry = _own(principal, request.params['id'], outgoing);
    if (entry == null) return MockResponse.error(404, FailureCodes.requestNotFound);
    if (entry['status'] != pending) return MockResponse.error(409, FailureCodes.requestNotPending);
    final now = _clock().toUtc();
    final remindedAt = entry['remindedAt'] as String?;
    if (remindedAt != null && now.difference(DateTime.parse(remindedAt)) < remindInterval) return MockResponse.error(429, FailureCodes.remindTooSoon);
    final updated = {...entry, 'remindedAt': now.toIso8601String()};
    await _store.put(MockCollections.moneyRequests, entry['id'] as String, updated);
    return MockResponse.ok(_view(updated, principal));
  });

  Future<MockResponse> _splits(MockRequest request) => _authenticator.guard(request, (principal) async {
    await _prepare(principal);
    final items = _store.all(MockCollections.splits).where((split) => split['userId'] == principal.userId).toList()..sort((first, second) => (second['createdAt'] as String).compareTo(first['createdAt'] as String));
    return MockResponse.ok({
      'items': [for (final split in items) _splitView(split)],
    });
  });

  Future<MockResponse> _split(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final note = request.body['note'];
    final invalid = _rejectAmount(amountCents) ?? MockRules.rejectNote(note);
    if (invalid != null) return invalid;
    final includeSelf = request.body['includeSelf'] == true;
    final phones = request.body['phones'];
    final self = _phoneOf(principal);
    if (phones is! List<dynamic> || phones.isEmpty || phones.length > maxParticipants || phones.toSet().length != phones.length) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'phones');
    for (final phone in phones) {
      if (phone is! String || !MockRules.phonePattern.hasMatch(phone)) return MockResponse.error(400, FailureCodes.invalidPhone, field: 'phones');
      if (phone == self) return MockResponse.error(422, FailureCodes.cannotRequestSelf);
      if (PaymentsMockModule.resolve(_store, phone) == null) return MockResponse.error(404, FailureCodes.payeeNotFound, field: 'phones');
    }
    final shares = Money(amountCents as int).split(phones.length + (includeSelf ? 1 : 0));
    final splitId = IdGenerator.next();
    final requestShares = includeSelf ? shares.skip(1).toList() : shares;
    final entries = [for (final (index, phone) in phones.cast<String>().indexed) await _open(principal, requestShares[index].cents, note as String?, phone, splitId: splitId)];
    final split = {
      'createdAt': _clock().toUtc().toIso8601String(),
      'id': splitId,
      'includeSelf': includeSelf,
      'note': note,
      'requestIds': [for (final entry in entries) entry['id']],
      'selfCents': includeSelf ? shares.first.cents : 0,
      'totalCents': amountCents,
      'userId': principal.userId,
    };
    await _store.put(MockCollections.splits, splitId, split);
    return MockResponse.created(_splitView(split));
  });

  MockResponse? _rejectAmount(Object? amountCents) => MockRules.rejectAmount(amountCents) ?? ((amountCents as int) > maxAmountCents ? MockResponse.error(400, FailureCodes.invalidAmount, field: 'amountCents') : null);

  Future<Map<String, dynamic>> _open(MockPrincipal principal, int amountCents, String? note, String phone, {String? splitId}) async {
    final user = _store.find(MockCollections.users, principal.userId)!;
    final payee = PaymentsMockModule.resolve(_store, phone)!;
    final now = _clock().toUtc().toIso8601String();
    final id = IdGenerator.next();
    final entry = {
      'amountCents': amountCents,
      'fromName': user['displayName'] ?? user['phone'],
      'fromPhone': user['phone'],
      'fromUserId': principal.userId,
      'id': id,
      'note': note,
      'remindedAt': null,
      'splitId': splitId,
      'status': pending,
      'toName': payee.name,
      'toPhone': phone,
      'toUserId': _userIdOf(phone),
      'createdAt': now,
      'updatedAt': now,
    };
    await _store.put(MockCollections.moneyRequests, id, entry);
    final toUserId = entry['toUserId'] as String?;
    if (toUserId != null) await _notifier.notify(toUserId, MockNotifier.requestReceived, params: {'amountCents': amountCents, 'name': entry['fromName']});
    return entry;
  }

  Future<MockResponse> _transition(MockRequest request, String direction, String status) => _authenticator.guard(request, (principal) async {
    final entry = _own(principal, request.params['id'], direction);
    if (entry == null) return MockResponse.error(404, FailureCodes.requestNotFound);
    if (entry['status'] != pending) return MockResponse.error(409, FailureCodes.requestNotPending);
    final updated = {...entry, 'status': status, 'updatedAt': _clock().toUtc().toIso8601String()};
    await _store.put(MockCollections.moneyRequests, entry['id'] as String, updated);
    return MockResponse.ok(_view(updated, principal));
  });

  Map<String, dynamic>? _own(MockPrincipal principal, Object? id, String direction) {
    final entry = id is String ? _store.find(MockCollections.moneyRequests, id) : null;
    if (entry == null) return null;
    final isMine = direction == outgoing ? entry['fromUserId'] == principal.userId : entry['toPhone'] == _phoneOf(principal);
    return isMine ? entry : null;
  }

  Future<void> _prepare(MockPrincipal principal) async {
    final now = _clock().toUtc();
    if (_store.find(MockCollections.requestSeeds, principal.userId) == null) {
      final created = now.subtract(_seedAge).toIso8601String();
      final id = IdGenerator.next();
      await _store.put(MockCollections.moneyRequests, id, {
        'amountCents': seedRequest.amountCents,
        'fromName': PaymentsMockModule.directory[seedRequest.phone],
        'fromPhone': seedRequest.phone,
        'fromUserId': null,
        'id': id,
        'note': seedRequest.note,
        'remindedAt': null,
        'splitId': null,
        'status': pending,
        'toName': null,
        'toPhone': _phoneOf(principal),
        'toUserId': principal.userId,
        'createdAt': created,
        'updatedAt': created,
      });
      await _store.put(MockCollections.requestSeeds, principal.userId, {'seededAt': now.toIso8601String()});
    }
    for (final entry in _store.all(MockCollections.moneyRequests).where((entry) => entry['fromUserId'] == principal.userId && entry['toUserId'] == null && entry['status'] == pending).toList()) {
      if (now.difference(DateTime.parse(entry['createdAt'] as String)) < directoryReplyDelay) continue;
      final phone = entry['toPhone'] as String;
      final user = _store.find(MockCollections.users, principal.userId)!;
      final transaction = await _ledger.post(
        amountCents: entry['amountCents'] as int,
        at: now,
        creditAccount: MockWalletSeeder.walletAccount(principal.userId),
        creditName: user['displayName'] as String? ?? user['phone'] as String,
        creditPhone: user['phone'] as String,
        debitAccount: PaymentsMockModule.directoryAccount(phone),
        debitName: entry['toName'] as String? ?? phone,
        debitPhone: phone,
        meta: {'kind': PaymentsMockModule.transferKind, 'phone': phone, 'requestId': entry['id']},
        note: entry['note'] as String?,
        reference: _ledger.nextReference(),
        type: MockWalletSeeder.transfer,
      );
      await _store.put(MockCollections.moneyRequests, entry['id'] as String, {...entry, 'paidTransactionId': transaction['id'], 'status': paid, 'updatedAt': now.toIso8601String()});
      await _notifier.notify(principal.userId, MockNotifier.requestPaid, params: {'amountCents': entry['amountCents'], 'name': entry['toName'] ?? phone, 'transactionId': transaction['id']});
    }
  }

  String _phoneOf(MockPrincipal principal) => _store.find(MockCollections.users, principal.userId)!['phone'] as String;

  String? _userIdOf(String phone) => _store.all(MockCollections.users).where((user) => user['phone'] == phone).firstOrNull?['id'] as String?;

  Map<String, dynamic> _view(Map<String, dynamic> entry, MockPrincipal principal) {
    final isOutgoing = entry['fromUserId'] == principal.userId;
    return {
      'amountCents': entry['amountCents'],
      'counterpartyName': isOutgoing ? entry['toName'] : entry['fromName'],
      'counterpartyPhone': isOutgoing ? entry['toPhone'] : entry['fromPhone'],
      'direction': isOutgoing ? outgoing : incoming,
      'id': entry['id'],
      'note': entry['note'],
      'remindedAt': entry['remindedAt'],
      'splitId': entry['splitId'],
      'status': entry['status'],
      'createdAt': entry['createdAt'],
    };
  }

  Map<String, dynamic> _splitView(Map<String, dynamic> split) {
    final requests = [for (final id in (split['requestIds'] as List<dynamic>).cast<String>()) ?_store.find(MockCollections.moneyRequests, id)];
    return {
      'id': split['id'],
      'note': split['note'],
      'shares': [
        if (split['includeSelf'] == true) {'amountCents': split['selfCents'], 'isSelf': true, 'name': null, 'phone': null, 'status': paid},
        for (final entry in requests) {'amountCents': entry['amountCents'], 'isSelf': false, 'name': entry['toName'], 'phone': entry['toPhone'], 'status': entry['status']},
      ],
      'totalCents': split['totalCents'],
      'createdAt': split['createdAt'],
    };
  }

  @override
  List<MockRoute> get routes => [
    MockRoute.get(ApiPaths.moneyRequests, _list),
    MockRoute.post(ApiPaths.moneyRequests, _create),
    MockRoute.post(ApiPaths.moneyRequestDecline, _decline),
    MockRoute.post(ApiPaths.moneyRequestCancel, _cancel),
    MockRoute.post(ApiPaths.moneyRequestRemind, _remind),
    MockRoute.get(ApiPaths.splits, _splits),
    MockRoute.post(ApiPaths.splits, _split),
  ];
}
