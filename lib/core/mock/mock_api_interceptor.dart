import 'dart:math';

import 'package:dio/dio.dart';

import '../errors/failure_codes.dart';
import '../security/request_canonicalizer.dart';
import 'mock_request.dart';
import 'mock_response.dart';
import 'mock_server.dart';

class MockApiInterceptor extends Interceptor {
  static const int _baseLatencyMs = 250;
  static const int _latencySpreadMs = 450;

  final MockServer _server;

  final Random _random = Random();

  MockApiInterceptor(this._server);

  Future<MockResponse> _respond(RequestOptions options) async {
    try {
      return await _server.handle(
        MockRequest(body: _asMap(options.data), headers: options.headers, method: options.method.toUpperCase(), path: Uri.parse(options.path).path, query: options.queryParameters, rawBody: RequestCanonicalizer.bodyOf(options.data)),
      );
    } on Object {
      return MockResponse.error(500, FailureCodes.unknown);
    }
  }

  Map<String, dynamic> _asMap(Object? data) => data is Map<String, dynamic> ? data : const {};

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await Future<void>.delayed(Duration(milliseconds: _baseLatencyMs + _random.nextInt(_latencySpreadMs)));
    final mockResponse = await _respond(options);
    final response = Response<Object?>(data: mockResponse.body, requestOptions: options, statusCode: mockResponse.statusCode);
    if (mockResponse.isError) {
      handler.reject(DioException.badResponse(requestOptions: options, response: response, statusCode: mockResponse.statusCode), true);
    } else {
      handler.resolve(response, true);
    }
  }
}
