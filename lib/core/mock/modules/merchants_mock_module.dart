import '../../errors/failure_codes.dart';
import '../../network/api_headers.dart';
import '../../network/api_paths.dart';
import '../../security/approval_payload.dart';
import '../../utils/lanka_qr.dart';
import '../mock_authenticator.dart';
import '../mock_checkout.dart';
import '../mock_module.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_rules.dart';

class MerchantsMockModule implements MockModule {
  static const String transactionType = 'merchant';

  static const Map<String, ({String category, String categoryCode, String city, String name})> directory = {
    'LKQR00000001': (category: 'grocery', categoryCode: '5411', city: 'Colombo 07', name: 'Keells Super'),
    'LKQR00000002': (category: 'grocery', categoryCode: '5411', city: 'Kandy', name: 'Cargills Food City'),
    'LKQR00000003': (category: 'transport', categoryCode: '4121', city: 'Colombo 03', name: 'PickMe'),
    'LKQR00000004': (category: 'dining', categoryCode: '5814', city: 'Colombo 03', name: 'Java Lounge'),
    'LKQR00000005': (category: 'shopping', categoryCode: '5311', city: 'Colombo 02', name: 'Arpico Supercentre'),
    'LKQR00000006': (category: 'fuel', categoryCode: '5541', city: 'Galle', name: 'Lanka IOC'),
    'LKQR00000007': (category: 'dining', categoryCode: '5814', city: 'Negombo', name: 'Barista'),
  };

  final MockAuthenticator _authenticator;

  final MockCheckout _checkout;

  const MerchantsMockModule(this._authenticator, this._checkout);

  static String merchantAccount(String merchantId) => 'merchant:$merchantId';

  Future<MockResponse> _lookup(MockRequest request) => _authenticator.guard(request, (principal) async {
    final (:code, :rejection) = _read(request.body['qr']);
    if (code == null) return rejection!;
    return MockResponse.ok({'amountCents': ?code.amount?.cents, 'merchant': _merchantJson(code.accountId)});
  });

  Future<MockResponse> _pay(MockRequest request) => _authenticator.guard(request, (principal) async {
    final amountCents = request.body['amountCents'];
    final note = request.body['note'];
    final invalid = MockRules.rejectKey(request) ?? MockRules.rejectAmount(amountCents) ?? MockRules.rejectNote(note);
    if (invalid != null) return invalid;
    final (:code, :rejection) = _read(request.body['qr']);
    if (code == null) return rejection!;
    final fixedAmount = code.amount;
    if (fixedAmount != null && fixedAmount.cents != amountCents) return MockResponse.error(422, FailureCodes.amountMismatch, field: 'amountCents');
    final merchant = directory[code.accountId]!;
    final charge = await _checkout.charge(
      principal,
      amountCents: amountCents as int,
      approval: request.body['approval'],
      approvalPayload: ApprovalPayload.merchantPayment(amountCents: amountCents, idempotencyKey: request.header(ApiHeaders.idempotencyKey)!, merchantId: code.accountId),
      creditAccount: merchantAccount(code.accountId),
      creditName: merchant.name,
      meta: {'category': merchant.category, 'kind': transactionType, 'merchantId': code.accountId, 'qr': request.body['qr']},
      note: note as String?,
      type: transactionType,
    );
    final transaction = charge.transaction;
    if (transaction == null) return charge.rejection!;
    return MockResponse.created(MockRules.receipt(transaction, extra: {'merchant': _merchantJson(code.accountId)}));
  });

  ({LankaQr? code, MockResponse? rejection}) _read(Object? qr) {
    if (qr is! String || qr.isEmpty) return (code: null, rejection: MockResponse.error(400, FailureCodes.invalidRequest, field: 'qr'));
    final LankaQr code;
    try {
      code = LankaQr.parse(qr);
    } on LankaQrException catch (exception) {
      return exception.issue == LankaQrIssue.currency ? (code: null, rejection: MockResponse.error(422, FailureCodes.unsupportedCurrency, field: 'qr')) : (code: null, rejection: MockResponse.error(400, FailureCodes.invalidQr, field: 'qr'));
    }
    if (code.isPersonal || !directory.containsKey(code.accountId)) return (code: null, rejection: MockResponse.error(404, FailureCodes.merchantNotFound));
    return (code: code, rejection: null);
  }

  Map<String, dynamic> _merchantJson(String merchantId) {
    final merchant = directory[merchantId]!;
    return {'category': merchant.category, 'city': merchant.city, 'id': merchantId, 'name': merchant.name};
  }

  @override
  List<MockRoute> get routes => [MockRoute.post(ApiPaths.merchantLookup, _lookup), MockRoute.post(ApiPaths.merchantPayments, _pay)];
}
