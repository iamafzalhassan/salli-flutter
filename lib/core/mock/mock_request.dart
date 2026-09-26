class MockRequest {
  final String method;
  final String path;
  final String rawBody;

  final Map<String, dynamic> body;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> query;

  final Map<String, String> params;

  const MockRequest({required this.method, required this.path, this.rawBody = '', required this.body, required this.headers, required this.query, this.params = const {}});

  String? header(String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value?.toString();
    }
    return null;
  }

  MockRequest withParams(Map<String, String> params) => MockRequest(body: body, headers: headers, method: method, params: params, path: path, query: query, rawBody: rawBody);
}
