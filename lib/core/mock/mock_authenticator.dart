import '../errors/failure_codes.dart';
import '../network/api_headers.dart';
import '../security/request_canonicalizer.dart';
import '../utils/id_generator.dart';
import 'mock_collections.dart';
import 'mock_principal.dart';
import 'mock_request.dart';
import 'mock_response.dart';
import 'mock_signature_verifier.dart';
import 'mock_store.dart';

class MockAuthenticator {
  static const int nonceSweepThreshold = 500;
  static const int tokenBytes = 32;

  static const String _bearerPrefix = 'Bearer ';

  static const Duration accessLifetime = Duration(minutes: 15);
  static const Duration maxClockSkew = Duration(seconds: 60);

  final DateTime Function() _clock;

  final MockStore _store;

  MockAuthenticator(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<void> bindDevice(String userId, Map<String, dynamic> device, {String? boundAt}) async {
    final deviceId = device['id'] as String;
    await _store.put(MockCollections.devices, deviceId, {'id': deviceId, 'platform': device['platform'], 'publicKey': device['publicKey'], 'userId': userId, 'boundAt': boundAt ?? _clock().toUtc().toIso8601String()});
  }

  Future<MockResponse> guard(MockRequest request, Future<MockResponse> Function(MockPrincipal principal) handler) async {
    final token = request.header(ApiHeaders.authorization);
    final access = token != null && token.startsWith(_bearerPrefix) ? _store.find(MockCollections.accessTokens, token.substring(_bearerPrefix.length)) : null;
    if (access == null) return MockResponse.error(401, FailureCodes.unauthorized);
    if (!_clock().toUtc().isBefore(DateTime.parse(access['expiresAt'] as String))) return MockResponse.error(401, FailureCodes.tokenExpired);
    final deviceId = access['deviceId'] as String;
    final rejection = await verifyDevice(request, deviceId);
    if (rejection != null) return rejection;
    return handler(MockPrincipal(deviceId: deviceId, refreshToken: access['refreshToken'] as String, userId: access['userId'] as String));
  }

  Future<MockResponse?> verifyDevice(MockRequest request, String expectedDeviceId) async {
    final deviceId = request.header(ApiHeaders.device);
    final nonce = request.header(ApiHeaders.nonce);
    final signature = request.header(ApiHeaders.signature);
    final timestamp = request.header(ApiHeaders.timestamp);
    if (deviceId == null || deviceId != expectedDeviceId || nonce == null || signature == null || timestamp == null) return MockResponse.error(401, FailureCodes.signatureInvalid);
    final rejection = await claimNonce(nonce, timestamp);
    if (rejection != null) return rejection;
    final device = _store.find(MockCollections.devices, deviceId);
    final payload = RequestCanonicalizer.canonicalize(body: request.rawBody, deviceId: deviceId, method: request.method, nonce: nonce, path: request.path, query: request.query, timestamp: timestamp);
    if (device == null || !MockSignatureVerifier.verify(payload: payload, publicKey: device['publicKey'] as String, signature: signature)) return MockResponse.error(401, FailureCodes.signatureInvalid);
    return null;
  }

  Future<MockResponse?> claimNonce(Object? nonce, Object? timestamp) async {
    final seconds = timestamp is String ? int.tryParse(timestamp) : null;
    final now = _clock().toUtc();
    if (nonce is! String || nonce.isEmpty || seconds == null) return MockResponse.error(401, FailureCodes.signatureInvalid);
    if (now.difference(DateTime.fromMillisecondsSinceEpoch(seconds * Duration.millisecondsPerSecond, isUtc: true)).abs() > maxClockSkew) return MockResponse.error(401, FailureCodes.signatureInvalid);
    if (_store.find(MockCollections.nonces, nonce) != null) return MockResponse.error(401, FailureCodes.replayedRequest);
    await _rememberNonce(nonce, now);
    return null;
  }

  Future<Map<String, dynamic>> issueSession(String userId, String deviceId, {String? family}) async {
    final accessToken = IdGenerator.next(bytes: tokenBytes);
    final refreshToken = IdGenerator.next(bytes: tokenBytes);
    final accessExpiresAt = _clock().toUtc().add(accessLifetime).toIso8601String();
    await _store.put(MockCollections.accessTokens, accessToken, {'deviceId': deviceId, 'refreshToken': refreshToken, 'userId': userId, 'expiresAt': accessExpiresAt});
    await _store.put(MockCollections.sessions, refreshToken, {'accessToken': accessToken, 'deviceId': deviceId, 'family': family ?? IdGenerator.next(), 'userId': userId});
    return {'accessToken': accessToken, 'refreshToken': refreshToken, 'accessExpiresAt': accessExpiresAt};
  }

  Future<bool> revokeReusedToken(String refreshToken) async {
    final retired = _store.find(MockCollections.retiredRefreshTokens, refreshToken);
    if (retired == null) return false;
    for (final session in _sessionsWhere((session) => session['family'] == retired['family'])) {
      await retire(session.key);
    }
    return true;
  }

  Future<void> revokeUser(String userId) async {
    for (final session in _sessionsWhere((session) => session['userId'] == userId)) {
      await retire(session.key);
    }
    for (final device in _store.entries(MockCollections.devices).where((device) => device.value['userId'] == userId)) {
      await _store.remove(MockCollections.devices, device.key);
    }
  }

  Future<void> retire(String refreshToken) async {
    final session = findSession(refreshToken);
    if (session == null) return;
    await _store.put(MockCollections.retiredRefreshTokens, refreshToken, {'family': session['family']});
    await _store.remove(MockCollections.accessTokens, session['accessToken'] as String);
    await _store.remove(MockCollections.sessions, refreshToken);
  }

  Map<String, dynamic>? findSession(String refreshToken) => _store.find(MockCollections.sessions, refreshToken);

  Future<void> _rememberNonce(String nonce, DateTime now) async {
    await _store.put(MockCollections.nonces, nonce, {'expiresAt': now.add(maxClockSkew * 2).toIso8601String()});
    final nonces = _store.entries(MockCollections.nonces);
    if (nonces.length < nonceSweepThreshold) return;
    for (final expired in nonces.where((entry) => now.isAfter(DateTime.parse(entry.value['expiresAt'] as String)))) {
      await _store.remove(MockCollections.nonces, expired.key);
    }
  }

  List<MapEntry<String, Map<String, dynamic>>> _sessionsWhere(bool Function(Map<String, dynamic> session) test) => _store.entries(MockCollections.sessions).where((entry) => test(entry.value)).toList();
}
