import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../errors/failure.dart';
import '../errors/failure_codes.dart';

class ApiException implements Exception {
  final int? statusCode;

  final Failure failure;

  const ApiException({this.statusCode, required this.failure});

  factory ApiException.fromDio(DioException exception) => switch (exception.type) {
    DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout || DioExceptionType.sendTimeout || DioExceptionType.transformTimeout => const ApiException(failure: Failure(FailureCodes.timeout)),
    DioExceptionType.connectionError => const ApiException(failure: Failure.network()),
    DioExceptionType.cancel => const ApiException(failure: Failure(FailureCodes.cancelled)),
    DioExceptionType.badResponse => ApiException(statusCode: exception.response?.statusCode, failure: _failureFrom(exception.response)),
    DioExceptionType.badCertificate || DioExceptionType.unknown => ApiException(failure: exception.error is PlatformException ? const Failure(FailureCodes.deviceSecurityUnavailable) : const Failure.unknown()),
  };

  static Failure _failureFrom(Response<Object?>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final error = data['error'] as Map<String, dynamic>;
      return Failure(error['code'] as String? ?? FailureCodes.unknown, field: error['field'] as String?);
    }
    return Failure(response?.statusCode == 401 ? FailureCodes.unauthorized : FailureCodes.unknown);
  }
}
