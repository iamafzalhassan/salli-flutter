import 'package:dio/dio.dart';

import '../errors/failure.dart';
import '../errors/failure_codes.dart';
import 'api_exception.dart';
import 'api_headers.dart';

class ApiClient {
  final Dio _dio;

  const ApiClient(this._dio);

  Future<Map<String, dynamic>> delete(String path) => _send(() => _dio.delete<Object?>(path));

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) => _send(() => _dio.get<Object?>(path, queryParameters: query));

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) => _send(() => _dio.patch<Object?>(path, data: body));

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body, String? idempotencyKey}) => _send(() => _dio.post<Object?>(path, data: body, options: _options(idempotencyKey)));

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) => _send(() => _dio.put<Object?>(path, data: body));

  Options? _options(String? idempotencyKey) => idempotencyKey == null ? null : Options(headers: {ApiHeaders.idempotencyKey: idempotencyKey});

  Future<Map<String, dynamic>> _send(Future<Response<Object?>> Function() request) async {
    try {
      final data = (await request()).data;
      if (data == null) return const {};
      if (data is Map<String, dynamic>) return data;
      throw const ApiException(failure: Failure(FailureCodes.malformedResponse));
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}
