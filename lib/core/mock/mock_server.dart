import '../errors/failure_codes.dart';
import '../network/api_headers.dart';
import 'mock_collections.dart';
import 'mock_module.dart';
import 'mock_request.dart';
import 'mock_response.dart';
import 'mock_route.dart';
import 'mock_store.dart';

class MockServer {
  final List<MockRoute> _routes;

  final MockStore _store;

  MockServer(List<MockModule> modules, this._store) : _routes = [for (final module in modules) ...module.routes];

  Future<MockResponse> handle(MockRequest request) async {
    final idempotencyKey = request.header(ApiHeaders.idempotencyKey);
    final key = idempotencyKey == null ? null : '${request.header(ApiHeaders.device)}|${request.method} ${request.path}|$idempotencyKey';
    final replay = key == null ? null : _store.find(MockCollections.idempotency, key);
    if (replay != null) return MockResponse(replay['statusCode'] as int, replay['body'] as Map<String, dynamic>);
    final response = await _dispatch(request);
    if (key != null && !response.isError) await _store.put(MockCollections.idempotency, key, {'statusCode': response.statusCode, 'body': response.body});
    return response;
  }

  Future<MockResponse> _dispatch(MockRequest request) async {
    for (final route in _routes) {
      final params = route.match(request.method, request.path);
      if (params != null) return route.handler(request.withParams(params));
    }
    return MockResponse.error(404, FailureCodes.notFound);
  }
}
