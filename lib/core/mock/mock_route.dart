import 'mock_request.dart';
import 'mock_response.dart';

typedef MockHandler = Future<MockResponse> Function(MockRequest request);

class MockRoute {
  static final RegExp _parameter = RegExp(r':(\w+)');

  final String method;
  final String pattern;

  final MockHandler handler;

  late final List<String> _names = [for (final match in _parameter.allMatches(pattern)) match.group(1)!];

  late final RegExp _matcher = RegExp('^${pattern.replaceAllMapped(_parameter, (_) => '([^/]+)')}\$');

  MockRoute(this.method, this.pattern, this.handler);

  MockRoute.delete(String pattern, MockHandler handler) : this('DELETE', pattern, handler);

  MockRoute.get(String pattern, MockHandler handler) : this('GET', pattern, handler);

  MockRoute.patch(String pattern, MockHandler handler) : this('PATCH', pattern, handler);

  MockRoute.post(String pattern, MockHandler handler) : this('POST', pattern, handler);

  MockRoute.put(String pattern, MockHandler handler) : this('PUT', pattern, handler);

  Map<String, String>? match(String method, String path) {
    if (method != this.method) return null;
    final match = _matcher.firstMatch(path);
    if (match == null) return null;
    return {for (var index = 0; index < _names.length; index++) _names[index]: Uri.decodeComponent(match.group(index + 1)!)};
  }
}
