import '../../errors/failure_codes.dart';
import '../../network/api_paths.dart';
import '../mock_authenticator.dart';
import '../mock_collections.dart';
import '../mock_module.dart';
import '../mock_notifier.dart';
import '../mock_principal.dart';
import '../mock_request.dart';
import '../mock_response.dart';
import '../mock_route.dart';
import '../mock_store.dart';

class NotificationsMockModule implements MockModule {
  static const int maxItems = 50;

  final MockAuthenticator _authenticator;

  final MockNotifier _notifier;

  final MockStore _store;

  const NotificationsMockModule(this._authenticator, this._notifier, this._store);

  Future<MockResponse> _list(MockRequest request) => _authenticator.guard(request, (principal) async {
    final items = await _own(principal);
    return MockResponse.ok({
      'items': [for (final item in items.take(maxItems)) _json(item)],
      'unreadCount': items.where((item) => item['isRead'] != true).length,
    });
  });

  Map<String, dynamic> _json(Map<String, dynamic> item) => {'id': item['id'], 'isRead': item['isRead'], 'kind': item['kind'], 'params': item['params'], 'createdAt': item['createdAt']};

  Future<MockResponse> _unreadCount(MockRequest request) => _authenticator.guard(request, (principal) async => MockResponse.ok({'unreadCount': (await _own(principal)).where((item) => item['isRead'] != true).length}));

  Future<MockResponse> _read(MockRequest request) => _authenticator.guard(request, (principal) async {
    final id = request.params['id'];
    final item = id is String ? _store.find(MockCollections.notifications, id) : null;
    if (item == null || item['userId'] != principal.userId) return MockResponse.error(404, FailureCodes.notFound);
    await _store.put(MockCollections.notifications, id as String, {...item, 'isRead': true});
    return const MockResponse.noContent();
  });

  Future<MockResponse> _readAll(MockRequest request) => _authenticator.guard(request, (principal) async {
    for (final item in (await _own(principal)).where((item) => item['isRead'] != true)) {
      await _store.put(MockCollections.notifications, item['id'] as String, {...item, 'isRead': true});
    }
    return const MockResponse.noContent();
  });

  Future<List<Map<String, dynamic>>> _own(MockPrincipal principal) async {
    bool isOwn(Map<String, dynamic> item) => item['userId'] == principal.userId;
    if (!_store.all(MockCollections.notifications).any(isOwn)) await _notifier.notify(principal.userId, MockNotifier.welcome);
    return _store.all(MockCollections.notifications).where(isOwn).toList()..sort((first, second) => (second['createdAt'] as String).compareTo(first['createdAt'] as String));
  }

  @override
  List<MockRoute> get routes => [
    MockRoute.get(ApiPaths.notifications, _list),
    MockRoute.get(ApiPaths.unreadNotifications, _unreadCount),
    MockRoute.post(ApiPaths.notificationRead, _read),
    MockRoute.post(ApiPaths.notificationsReadAll, _readAll),
  ];
}
