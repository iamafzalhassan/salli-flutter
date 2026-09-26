import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class RequestCanonicalizer {
  static String bodyOf(Object? data) => data == null ? '' : jsonEncode(data);

  static List<int> canonicalize({required String body, required String deviceId, required String method, required String nonce, required String path, required Map<String, dynamic> query, required String timestamp}) =>
      utf8.encode([method.toUpperCase(), path, canonicalQuery(query), sha256.convert(utf8.encode(body)).toString(), timestamp, nonce, deviceId].join('\n'));

  static String canonicalQuery(Map<String, dynamic> query) {
    final keys = query.keys.toList()..sort();
    return [for (final key in keys) '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent('${query[key]}')}'].join('&');
  }
}
