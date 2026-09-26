import '../../network/api_paths.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_module.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_store.dart';

class SecurityMockModule implements MockModule {
  static const int maxEvents = 50;

  final MockAuthenticator _authenticator;

  final MockStore _store;

  const SecurityMockModule(this._authenticator, this._store);

  Future<MockResponse> _events(MockRequest request) => _authenticator.guard(request, (principal) async {
    final events = _store.all(MockCollections.securityEvents).where((event) => event['userId'] == principal.userId).toList()..sort((first, second) => (second['createdAt'] as String).compareTo(first['createdAt'] as String));
    return MockResponse.ok({
      'items': [
        for (final event in events.take(maxEvents)) {'id': event['id'], 'kind': event['kind'], 'platform': event['platform'], 'createdAt': event['createdAt']},
      ],
    });
  });

  Future<MockResponse> _devices(MockRequest request) => _authenticator.guard(request, (principal) async {
    final devices = _store.all(MockCollections.devices).where((device) => device['userId'] == principal.userId);
    return MockResponse.ok({
      'items': [
        for (final device in devices) {'boundAt': device['boundAt'], 'hasBiometricKey': device['biometricKey'] != null, 'id': device['id'], 'isCurrent': device['id'] == principal.deviceId, 'platform': device['platform']},
      ],
    });
  });

  @override
  List<MockRoute> get routes => [MockRoute.get(ApiPaths.securityEvents, _events), MockRoute.get(ApiPaths.devices, _devices)];
}
