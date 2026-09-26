import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/security/request_canonicalizer.dart';

void main() {
  group('RequestCanonicalizer', () {
    test('an empty body is an empty string, not JSON null', () => expect(RequestCanonicalizer.bodyOf(null), isEmpty));

    test('query parameters are sorted by name', () => expect(RequestCanonicalizer.canonicalQuery({'limit': 20, 'cursor': 'a b'}), 'cursor=a+b&limit=20'));

    test('the canonical form joins every signed part in a fixed order', () {
      final canonical = utf8.decode(RequestCanonicalizer.canonicalize(body: '{"a":1}', deviceId: 'device', method: 'post', nonce: 'nonce', path: '/v1/x', query: const {}, timestamp: '100'));
      expect(canonical, ['POST', '/v1/x', '', sha256.convert(utf8.encode('{"a":1}')).toString(), '100', 'nonce', 'device'].join('\n'));
    });
  });
}
