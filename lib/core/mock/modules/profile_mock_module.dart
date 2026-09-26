import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_kyc_reviewer.dart';
import '../mock_module.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_store.dart';
import 'kyc_mock_module.dart';

class ProfileMockModule implements MockModule {
  static const int maxNameLength = 60;
  static const int minAge = 16;
  static const int minNameLength = 2;

  final DateTime Function() _clock;

  final MockAuthenticator _authenticator;

  final MockKycReviewer _reviewer;

  final MockStore _store;

  ProfileMockModule(this._authenticator, this._reviewer, this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<MockResponse> _me(MockRequest request) => _authenticator.guard(request, (principal) async {
    final user = await _reviewer.settle(principal.userId);
    if (user == null) return MockResponse.error(404, FailureCodes.notFound);
    return MockResponse.ok(_meJson(user));
  });

  Future<MockResponse> _update(MockRequest request) => _authenticator.guard(request, (principal) async {
    final user = _store.find(MockCollections.users, principal.userId);
    if (user == null) return MockResponse.error(404, FailureCodes.notFound);
    final displayName = request.body['displayName'];
    final rawDate = request.body['dateOfBirth'];
    if (displayName != null && (displayName is! String || displayName.trim().length < minNameLength || displayName.trim().length > maxNameLength)) return MockResponse.error(400, FailureCodes.invalidName, field: 'displayName');
    final dateOfBirth = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (rawDate != null && (dateOfBirth == null || !_isOldEnough(dateOfBirth))) return MockResponse.error(400, FailureCodes.invalidDateOfBirth, field: 'dateOfBirth');
    if (dateOfBirth != null && user['kycStatus'] == MockKycReviewer.verified) return MockResponse.error(409, FailureCodes.kycAlreadySubmitted, field: 'dateOfBirth');
    final updated = {...user, if (displayName is String) 'displayName': displayName.trim(), if (dateOfBirth != null) 'dateOfBirth': DateTime.utc(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day).toIso8601String()};
    await _store.put(MockCollections.users, principal.userId, updated);
    return MockResponse.ok(_meJson(updated));
  });

  bool _isOldEnough(DateTime dateOfBirth) {
    final now = _clock().toUtc();
    return !DateTime.utc(dateOfBirth.year + minAge, dateOfBirth.month, dateOfBirth.day).isAfter(now) && dateOfBirth.year > 1900;
  }

  Map<String, dynamic> _meJson(Map<String, dynamic> user) => {'dateOfBirth': user['dateOfBirth'], 'displayName': user['displayName'], 'id': user['id'], 'phone': user['phone'], 'verification': KycMockModule.verificationJson(user)};

  @override
  List<MockRoute> get routes => [MockRoute.get(ApiPaths.me, _me), MockRoute.patch(ApiPaths.me, _update)];
}
