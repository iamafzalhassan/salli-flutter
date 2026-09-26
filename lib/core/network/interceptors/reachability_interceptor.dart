import 'package:dio/dio.dart';

import '../network_status.dart';

class ReachabilityInterceptor extends Interceptor {
  static const Set<DioExceptionType> _offlineTypes = {DioExceptionType.connectionError, DioExceptionType.connectionTimeout};

  final NetworkStatus _status;

  ReachabilityInterceptor(this._status);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_offlineTypes.contains(err.type)) {
      _status.markOffline();
    } else if (err.response != null) {
      _status.markOnline();
    }
    handler.next(err);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _status.markOnline();
    handler.next(response);
  }
}
