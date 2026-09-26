class MockResponse {
  final int statusCode;

  final Map<String, dynamic> body;

  const MockResponse(this.statusCode, this.body);

  const MockResponse.created(Map<String, dynamic> body) : this(201, body);

  MockResponse.error(int statusCode, String code, {String? field})
    : this(statusCode, {
        'error': {'code': code, 'field': ?field},
      });

  const MockResponse.noContent() : this(204, const {});

  const MockResponse.ok(Map<String, dynamic> body) : this(200, body);

  bool get isError => statusCode >= 400;

  String? get errorCode => (body['error'] as Map<String, dynamic>?)?['code'] as String?;
}
