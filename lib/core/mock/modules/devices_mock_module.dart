import 'dart:convert';

import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_module.dart';
import '../mock_pin_verifier.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_security_log.dart';
import '../mock_store.dart';

class DevicesMockModule implements MockModule {
  static const int publicKeyLength = 65;
  static const int uncompressedPointPrefix = 4;

  final MockAuthenticator _authenticator;

  final MockPinVerifier _pinVerifier;

  final MockSecurityLog _securityLog;

  final MockStore _store;

  const DevicesMockModule(this._authenticator, this._pinVerifier, this._securityLog, this._store);

  Future<MockResponse> _enroll(MockRequest request) => _authenticator.guard(request, (principal) async {
    final publicKey = request.body['publicKey'];
    if (publicKey is! String || !_isPublicKey(publicKey)) return MockResponse.error(400, FailureCodes.invalidDeviceKey, field: 'publicKey');
    final rejection = await _pinVerifier.verify(principal.userId, request.body['pinHash']);
    if (rejection != null) return rejection;
    final device = _store.find(MockCollections.devices, principal.deviceId)!;
    await _store.put(MockCollections.devices, principal.deviceId, {...device, 'biometricKey': publicKey});
    await _securityLog.record(principal.userId, MockSecurityLog.biometricsEnabled, platform: device['platform'] as String?);
    return const MockResponse.noContent();
  });

  bool _isPublicKey(String publicKey) {
    try {
      final bytes = base64Decode(publicKey);
      return bytes.length == publicKeyLength && bytes.first == uncompressedPointPrefix;
    } on FormatException {
      return false;
    }
  }

  Future<MockResponse> _remove(MockRequest request) => _authenticator.guard(request, (principal) async {
    final device = _store.find(MockCollections.devices, principal.deviceId);
    if (device != null && device['biometricKey'] != null) {
      await _store.put(MockCollections.devices, principal.deviceId, {...device}..remove('biometricKey'));
      await _securityLog.record(principal.userId, MockSecurityLog.biometricsDisabled, platform: device['platform'] as String?);
    }
    return const MockResponse.noContent();
  });

  @override
  List<MockRoute> get routes => [MockRoute.post(ApiPaths.biometricKey, _enroll), MockRoute.delete(ApiPaths.biometricKey, _remove)];
}
