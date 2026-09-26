import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/mock/mock_request.dart';
import 'package:salli/core/mock/mock_response.dart';
import 'package:salli/core/mock/mock_route.dart';

void main() {
  Future<MockResponse> handler(MockRequest request) async => const MockResponse.noContent();

  group('MockRoute.match', () {
    test('extracts every path parameter', () => expect(MockRoute.get('/v1/users/:id/cards/:cardId', handler).match('GET', '/v1/users/42/cards/abc'), {'id': '42', 'cardId': 'abc'}));

    test('decodes encoded parameters', () => expect(MockRoute.get('/v1/payees/:name', handler).match('GET', '/v1/payees/Nimal%20Perera'), {'name': 'Nimal Perera'}));

    test('returns an empty map for a static path', () => expect(MockRoute.post('/v1/otp', handler).match('POST', '/v1/otp'), isEmpty));

    test('rejects another method', () => expect(MockRoute.post('/v1/otp', handler).match('GET', '/v1/otp'), isNull));

    test('rejects a longer path', () => expect(MockRoute.get('/v1/users/:id', handler).match('GET', '/v1/users/42/cards'), isNull));
  });
}
