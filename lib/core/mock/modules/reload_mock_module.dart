import '../../errors/failure_codes.dart';
import '../../network/api_headers.dart';
import '../../network/api_paths.dart';
import '../../security/approval_payload.dart';
import '../../utils/mobile_operator.dart';
import '../mock_authenticator.dart';
import '../mock_checkout.dart';
import '../mock_ledger.dart';
import '../mock_module.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_rules.dart';
import '../mock_wallet_seeder.dart';

class ReloadMockModule implements MockModule {
  static const int maxAmountCents = 1000000;
  static const int maxRecent = 6;
  static const int minAmountCents = 2000;
  static const int _nationalPrefixEnd = 5;
  static const int _nationalPrefixStart = 3;

  static const String transactionType = 'reload';

  static const List<int> amounts = [5000, 10000, 20000, 50000, 100000];

  static const Map<String, List<({int amountCents, int? dataMb, String id, String kind, int? minutes, String name, int validityDays})>> plans = {
    'airtel': [
      (amountCents: 30000, dataMb: 3072, id: 'airtel-data-3', kind: 'data', minutes: null, name: 'Data 3GB', validityDays: 30),
      (amountCents: 85000, dataMb: 10240, id: 'airtel-data-10', kind: 'data', minutes: null, name: 'Data 10GB', validityDays: 30),
      (amountCents: 22500, dataMb: null, id: 'airtel-voice-350', kind: 'voice', minutes: 350, name: 'Any network 350 min', validityDays: 30),
    ],
    'dialog': [
      (amountCents: 29800, dataMb: 2048, id: 'dialog-data-2', kind: 'data', minutes: null, name: 'Anytime 2GB', validityDays: 30),
      (amountCents: 79800, dataMb: 8192, id: 'dialog-data-8', kind: 'data', minutes: null, name: 'Anytime 8GB', validityDays: 30),
      (amountCents: 179800, dataMb: 25600, id: 'dialog-data-25', kind: 'data', minutes: null, name: 'Anytime 25GB', validityDays: 30),
      (amountCents: 24900, dataMb: null, id: 'dialog-voice-300', kind: 'voice', minutes: 300, name: 'Any network 300 min', validityDays: 30),
      (amountCents: 59900, dataMb: null, id: 'dialog-voice-1000', kind: 'voice', minutes: 1000, name: 'Any network 1000 min', validityDays: 30),
      (amountCents: 99800, dataMb: 5120, id: 'dialog-combo-5', kind: 'combo', minutes: 500, name: 'Blaster 5GB + 500 min', validityDays: 30),
    ],
    'hutch': [
      (amountCents: 29700, dataMb: 4096, id: 'hutch-data-4', kind: 'data', minutes: null, name: 'Data 4GB', validityDays: 30),
      (amountCents: 99700, dataMb: 15360, id: 'hutch-data-15', kind: 'data', minutes: null, name: 'Data 15GB', validityDays: 30),
      (amountCents: 25000, dataMb: null, id: 'hutch-voice-500', kind: 'voice', minutes: 500, name: 'Voice 500 min', validityDays: 30),
    ],
    'mobitel': [
      (amountCents: 34900, dataMb: 3072, id: 'mobitel-data-3', kind: 'data', minutes: null, name: 'Non-stop 3GB', validityDays: 30),
      (amountCents: 99900, dataMb: 12288, id: 'mobitel-data-12', kind: 'data', minutes: null, name: 'Non-stop 12GB', validityDays: 30),
      (amountCents: 29900, dataMb: null, id: 'mobitel-voice-400', kind: 'voice', minutes: 400, name: 'Talk 400 min', validityDays: 30),
      (amountCents: 89900, dataMb: 6144, id: 'mobitel-combo-6', kind: 'combo', minutes: 400, name: 'Combo 6GB + 400 min', validityDays: 30),
    ],
  };

  static const Map<String, String> operatorNames = {'airtel': 'Airtel', 'dialog': 'Dialog', 'hutch': 'Hutch', 'mobitel': 'SLT-Mobitel'};

  final MockAuthenticator _authenticator;

  final MockCheckout _checkout;

  final MockLedger _ledger;

  final MockWalletSeeder _seeder;

  const ReloadMockModule(this._authenticator, this._checkout, this._ledger, this._seeder);

  static String operatorOf(String phone) => MobileOperator.forPrefix(phone.substring(_nationalPrefixStart, _nationalPrefixEnd))!.name;

  static String operatorAccount(String operator) => 'operator:$operator';

  Future<MockResponse> _plans(MockRequest request) => _authenticator.guard(request, (principal) async {
    final operator = request.query['operator'];
    final items = plans[operator];
    if (operator is! String || items == null) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'operator');
    return MockResponse.ok({
      'amounts': amounts,
      'items': [for (final plan in items) _planJson(plan)],
    });
  });

  Future<MockResponse> _recent(MockRequest request) => _authenticator.guard(request, (principal) async {
    await _seeder.ensureSeeded(principal.userId);
    final recent = <String, int>{};
    for (final transaction in _ledger.transactionsFor(MockWalletSeeder.walletAccount(principal.userId)).where((transaction) => transaction['type'] == transactionType)) {
      final phone = (transaction['meta'] as Map<String, dynamic>?)?['phone'] as String?;
      if (phone != null && recent.length < maxRecent) recent.putIfAbsent(phone, () => transaction['amountCents'] as int);
    }
    return MockResponse.ok({
      'items': [
        for (final MapEntry(key: phone, value: amountCents) in recent.entries) {'lastAmountCents': amountCents, 'phone': phone},
      ],
    });
  });

  Future<MockResponse> _reload(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final note = request.body['note'];
    final invalid = MockRules.rejectKey(request) ?? MockRules.rejectAmount(amountCents) ?? MockRules.rejectNote(note);
    if (invalid != null) return invalid;
    final phone = request.body['phone'];
    if (phone is! String || !MockRules.phonePattern.hasMatch(phone)) return MockResponse.error(400, FailureCodes.invalidPhone, field: 'phone');
    final operator = operatorOf(phone);
    final planId = request.body['planId'];
    final plan = planId == null ? null : plans[operator]!.where((plan) => plan.id == planId).firstOrNull;
    if (planId != null && plan == null) return MockResponse.error(404, FailureCodes.planNotFound);
    if (plan != null && plan.amountCents != amountCents) return MockResponse.error(422, FailureCodes.amountMismatch, field: 'amountCents');
    if (plan == null && ((amountCents as int) < minAmountCents || amountCents > maxAmountCents)) return MockResponse.error(422, FailureCodes.reloadAmountOutOfRange, field: 'amountCents');
    final charge = await _checkout.charge(
      principal,
      amountCents: amountCents as int,
      approval: request.body['approval'],
      approvalPayload: ApprovalPayload.reload(amountCents: amountCents, idempotencyKey: request.header(ApiHeaders.idempotencyKey)!, phone: phone, planId: plan?.id),
      creditAccount: operatorAccount(operator),
      creditName: operatorNames[operator]!,
      creditPhone: phone,
      meta: {'kind': transactionType, 'operator': operator, 'phone': phone, 'planId': ?plan?.id},
      note: note as String?,
      type: transactionType,
    );
    final transaction = charge.transaction;
    if (transaction == null) return charge.rejection!;
    return MockResponse.created(MockRules.receipt(transaction, extra: {'operator': operator, 'phone': phone, 'planName': ?plan?.name}));
  });

  Map<String, dynamic> _planJson(({int amountCents, int? dataMb, String id, String kind, int? minutes, String name, int validityDays}) plan) => {
    'amountCents': plan.amountCents,
    'dataMb': plan.dataMb,
    'id': plan.id,
    'kind': plan.kind,
    'minutes': plan.minutes,
    'name': plan.name,
    'validityDays': plan.validityDays,
  };

  @override
  List<MockRoute> get routes => [MockRoute.get(ApiPaths.reloadPlans, _plans), MockRoute.get(ApiPaths.recentReloads, _recent), MockRoute.post(ApiPaths.reloads, _reload)];
}
