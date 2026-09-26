import 'package:dio/dio.dart';

import '../../errors/failure_codes.dart';
import '../../security/session.dart';
import '../../security/session_store.dart';
import '../api_headers.dart';
import '../token_refresher.dart';

class AuthInterceptor extends QueuedInterceptor {
  static const String _retriedKey = 'salli.retried';

  static const Duration _refreshMargin = Duration(seconds: 30);

  final Dio _dio;

  final SessionStore _sessionStore;

  final TokenRefresher _tokenRefresher;

  AuthInterceptor(this._dio, this._sessionStore, this._tokenRefresher);

  bool _isExpiredToken(DioException error) {
    final data = error.response?.data;
    if (error.response?.statusCode != 401 || data is! Map<String, dynamic>) return false;
    final envelope = data['error'];
    return envelope is Map<String, dynamic> && envelope['code'] == FailureCodes.tokenExpired;
  }

  Future<Session?> _validSession() async {
    final session = _sessionStore.current;
    if (session == null || !session.isAccessExpiredAt(DateTime.now().add(_refreshMargin))) return session;
    return _tokenRefresher.refresh();
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_isExpiredToken(err) || err.requestOptions.extra[_retriedKey] == true) return handler.next(err);
    final session = await _tokenRefresher.refresh();
    if (session == null) return handler.next(err);
    try {
      handler.resolve(await _dio.fetch<Object?>(err.requestOptions..extra[_retriedKey] = true));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final session = await _validSession();
    if (session != null) options.headers[ApiHeaders.authorization] = 'Bearer ${session.accessToken}';
    handler.next(options);
  }
}
