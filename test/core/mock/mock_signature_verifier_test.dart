import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/mock/mock_signature_verifier.dart';

import '../../helpers/test_device_key.dart';

void main() {
  final key = TestDeviceKey.generate(1);
  final payload = utf8.encode('GET\n/v1/wallet\n\nhash\n1790000000\nnonce\ndevice');

  group('MockSignatureVerifier.verify', () {
    test('accepts a DER signature from the matching key', () => expect(MockSignatureVerifier.verify(payload: payload, publicKey: key.publicKey, signature: key.sign(payload)), isTrue));

    test('rejects a tampered payload', () => expect(MockSignatureVerifier.verify(payload: utf8.encode('tampered'), publicKey: key.publicKey, signature: key.sign(payload)), isFalse));

    test('rejects a signature from another key', () => expect(MockSignatureVerifier.verify(payload: payload, publicKey: key.publicKey, signature: TestDeviceKey.generate(2).sign(payload)), isFalse));

    test('rejects malformed input without throwing', () {
      expect(MockSignatureVerifier.verify(payload: payload, publicKey: 'not-base64', signature: key.sign(payload)), isFalse);
      expect(MockSignatureVerifier.verify(payload: payload, publicKey: key.publicKey, signature: base64Encode([1, 2, 3])), isFalse);
    });
  });
}
