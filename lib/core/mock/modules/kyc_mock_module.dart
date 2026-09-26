import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../../utils/gender.dart';
import '../../utils/nic.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_kyc_reviewer.dart';
import '../mock_ledger.dart';
import '../mock_limits.dart';
import '../mock_module.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_store.dart';
import '../mock_wallet_seeder.dart';

class KycMockModule implements MockModule {
  static const int minNameLength = 3;
  static const int _visibleNicDigits = 4;

  static const String _mask = '•';

  static final RegExp _digest = RegExp(r'^[0-9a-f]{64}$');

  final DateTime Function() _clock;

  final MockAuthenticator _authenticator;

  final MockKycReviewer _reviewer;

  final MockLedger _ledger;

  final MockStore _store;

  KycMockModule(this._authenticator, this._reviewer, this._ledger, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static Map<String, dynamic> verificationJson(Map<String, dynamic> user) {
    final nic = user['nic'] as String?;
    return {
      'maskedNic': nic == null ? null : '${_mask * (nic.length - _visibleNicDigits)}${nic.substring(nic.length - _visibleNicDigits)}',
      'rejectionReason': user['kycRejectionReason'],
      'reviewedAt': user['kycReviewedAt'],
      'status': user['kycStatus'] ?? MockKycReviewer.notStarted,
      'submittedAt': user['kycSubmittedAt'],
      'tier': MockLimits.tierOf(user),
    };
  }

  Future<MockResponse> _verification(MockRequest request) => _authenticator.guard(request, (principal) async => MockResponse.ok(verificationJson((await _reviewer.settle(principal.userId))!)));

  Future<MockResponse> _submit(MockRequest request) => _authenticator.guard(request, (principal) async {
    final user = (await _reviewer.settle(principal.userId))!;
    final status = user['kycStatus'];
    if (status == MockKycReviewer.pending || status == MockKycReviewer.verified) return MockResponse.error(409, FailureCodes.kycAlreadySubmitted);
    final fullName = request.body['fullName'];
    if (fullName is! String || fullName.trim().length < minNameLength) return MockResponse.error(400, FailureCodes.invalidName, field: 'fullName');
    final nic = request.body['nic'] is String ? Nic.tryParse(request.body['nic'] as String) : null;
    if (nic == null) return MockResponse.error(400, FailureCodes.invalidNic, field: 'nic');
    final dateOfBirth = request.body['dateOfBirth'] is String ? DateTime.tryParse(request.body['dateOfBirth'] as String) : null;
    if (dateOfBirth == null) return MockResponse.error(400, FailureCodes.invalidDateOfBirth, field: 'dateOfBirth');
    final gender = Gender.values.asNameMap()[request.body['gender']];
    if (gender == null) return MockResponse.error(400, FailureCodes.invalidRequest, field: 'gender');
    final nicDate = nic.dateOfBirth;
    if (nicDate.year != dateOfBirth.year || nicDate.month != dateOfBirth.month || nicDate.day != dateOfBirth.day || nic.gender != gender) return MockResponse.error(422, FailureCodes.nicMismatch, field: 'nic');
    final documents = request.body['documents'];
    if (documents is! Map<String, dynamic> || !['nicBack', 'nicFront', 'selfie'].every((name) => documents[name] is String && _digest.hasMatch(documents[name] as String))) {
      return MockResponse.error(400, FailureCodes.invalidRequest, field: 'documents');
    }
    final liveness = request.body['liveness'];
    if (liveness is! Map<String, dynamic> || liveness['passed'] != true || liveness['challenges'] is! List<dynamic> || (liveness['challenges'] as List<dynamic>).isEmpty) {
      return MockResponse.error(400, FailureCodes.invalidRequest, field: 'liveness');
    }
    final updated = {
      ...user,
      'dateOfBirth': _dateOnly(dateOfBirth),
      'fullName': fullName.trim(),
      'gender': gender.name,
      'kycRejectionReason': null,
      'kycReviewedAt': null,
      'kycStatus': MockKycReviewer.pending,
      'kycSubmittedAt': _clock().toUtc().toIso8601String(),
      'nic': nic.number,
    };
    await _store.put(MockCollections.users, principal.userId, updated);
    return MockResponse(202, verificationJson(updated));
  });

  Future<MockResponse> _limits(MockRequest request) => _authenticator.guard(request, (principal) async {
    final user = await _reviewer.settle(principal.userId);
    final limits = MockLimits.of(user);
    final account = MockWalletSeeder.walletAccount(principal.userId);
    final now = _clock().toUtc();
    return MockResponse.ok({
      'dailyCents': limits.dailyCents,
      'dailyUsedCents': _ledger.outgoingSince(account, now.subtract(MockLimits.dailyWindow)),
      'monthlyCents': limits.monthlyCents,
      'monthlyUsedCents': _ledger.outgoingSince(account, now.subtract(MockLimits.monthlyWindow)),
      'perPaymentCents': limits.perPaymentCents,
      'tier': MockLimits.tierOf(user),
    });
  });

  String _dateOnly(DateTime date) => DateTime.utc(date.year, date.month, date.day).toIso8601String();

  @override
  List<MockRoute> get routes => [MockRoute.get(ApiPaths.kyc, _verification), MockRoute.post(ApiPaths.kyc, _submit), MockRoute.get(ApiPaths.limits, _limits)];
}
