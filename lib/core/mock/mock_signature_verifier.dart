import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

abstract final class MockSignatureVerifier {
  static const int _integerTag = 0x02;
  static const int _minimumLength = 8;
  static const int _sequenceTag = 0x30;

  static bool verify({required List<int> payload, required String publicKey, required String signature}) {
    try {
      final domain = ECCurve_secp256r1();
      final point = domain.curve.decodePoint(base64Decode(publicKey));
      final decoded = _decodeDer(base64Decode(signature));
      if (point == null || decoded == null) return false;
      final signer = ECDSASigner(SHA256Digest())..init(false, PublicKeyParameter<ECPublicKey>(ECPublicKey(point, domain)));
      return signer.verifySignature(Uint8List.fromList(payload), decoded);
    } on Object {
      return false;
    }
  }

  static ECSignature? _decodeDer(List<int> bytes) {
    if (bytes.length < _minimumLength || bytes[0] != _sequenceTag || bytes[1] != bytes.length - 2) return null;
    final r = _readInteger(bytes, 2);
    final s = r == null ? null : _readInteger(bytes, r.$2);
    if (r == null || s == null || s.$2 != bytes.length) return null;
    return ECSignature(r.$1, s.$1);
  }

  static (BigInt, int)? _readInteger(List<int> bytes, int offset) {
    if (offset + 2 > bytes.length || bytes[offset] != _integerTag) return null;
    final end = offset + 2 + bytes[offset + 1];
    if (end > bytes.length) return null;
    return (bytes.sublist(offset + 2, end).fold<BigInt>(BigInt.zero, (value, byte) => (value << 8) | BigInt.from(byte)), end);
  }
}
