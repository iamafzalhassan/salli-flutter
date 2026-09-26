import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../security/device_identity.dart';
import '../../security/request_canonicalizer.dart';
import '../../security/session_store.dart';
import '../../utils/id_generator.dart';
import '../api_headers.dart';

class SigningInterceptor extends Interceptor {
  final DeviceIdentity _deviceIdentity;

  final SessionStore _sessionStore;

  SigningInterceptor(this._deviceIdentity, this._sessionStore);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final deviceId = _sessionStore.isSignedIn ? await _deviceIdentity.currentId() : null;
    if (deviceId == null) return handler.next(options);
    try {
      final timestamp = '${DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond}';
      final nonce = IdGenerator.next();
      final payload = RequestCanonicalizer.canonicalize(
        body: RequestCanonicalizer.bodyOf(options.data),
        deviceId: deviceId,
        method: options.method,
        nonce: nonce,
        path: Uri.parse(options.path).path,
        query: options.queryParameters,
        timestamp: timestamp,
      );
      options.headers.addAll({ApiHeaders.device: deviceId, ApiHeaders.nonce: nonce, ApiHeaders.signature: await _deviceIdentity.sign(payload), ApiHeaders.timestamp: timestamp});
      handler.next(options);
    } on PlatformException catch (exception) {
      handler.reject(DioException(error: exception, requestOptions: options));
    }
  }
}
