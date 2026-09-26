import 'package:dio/dio.dart';

import '../security/session.dart';
import '../security/session_codec.dart';
import '../security/session_store.dart';
import 'api_paths.dart';

class TokenRefresher {
  static const Set<int> _rejectedStatuses = {401, 403};

  final Dio _dio;

  final SessionStore _sessionStore;

  Future<Session?>? _inFlight;

  TokenRefresher(this._dio, this._sessionStore);

  Future<Session?> refresh() => _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  Future<Session?> _refresh() async {
    final current = _sessionStore.current;
    if (current == null) return null;
    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiPaths.refresh, data: {'refreshToken': current.refreshToken});
      final session = SessionCodec.fromApi(response.data!);
      await _sessionStore.save(session);
      return session;
    } on DioException catch (exception) {
      if (_rejectedStatuses.contains(exception.response?.statusCode)) await _sessionStore.clear();
      return null;
    }
  }
}
