import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:salli/core/network/api_headers.dart';
import 'package:salli/core/security/request_canonicalizer.dart';

class TestDeviceKey {
  static const int _hmacBlockSize = 64;
  static const int _seedLength = 32;

  final ECPrivateKey _privateKey;

  final ECPublicKey _publicKey;

  TestDeviceKey._(this._privateKey, this._publicKey);

  factory TestDeviceKey.generate(int seed) {
    final random = FortunaRandom()..seed(KeyParameter(Uint8List.fromList([for (var index = 0; index < _seedLength; index++) (index * 31 + seed) & 0xff])));
    final generator = ECKeyGenerator()..init(ParametersWithRandom(ECKeyGeneratorParameters(ECCurve_secp256r1()), random));
    final pair = generator.generateKeyPair();
    return TestDeviceKey._(pair.privateKey, pair.publicKey);
  }

  String get publicKey => base64Encode(_publicKey.Q!.getEncoded(false));

  Map<String, dynamic> signedHeaders({required String deviceId, required String method, required String nonce, required String path, required DateTime signedAt, Object? body, Map<String, dynamic> query = const {}}) {
    final timestamp = '${signedAt.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond}';
    final payload = RequestCanonicalizer.canonicalize(body: RequestCanonicalizer.bodyOf(body), deviceId: deviceId, method: method, nonce: nonce, path: path, query: query, timestamp: timestamp);
    return {ApiHeaders.device: deviceId, ApiHeaders.nonce: nonce, ApiHeaders.signature: sign(payload), ApiHeaders.timestamp: timestamp};
  }

  String sign(List<int> payload) {
    final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), _hmacBlockSize))..init(true, PrivateKeyParameter<ECPrivateKey>(_privateKey));
    final signature = signer.generateSignature(Uint8List.fromList(payload)) as ECSignature;
    final r = _derInteger(signature.r);
    final s = _derInteger(signature.s);
    return base64Encode([0x30, r.length + s.length, ...r, ...s]);
  }

  static List<int> _derInteger(BigInt value) {
    final hex = value.toRadixString(16);
    final padded = hex.length.isOdd ? '0$hex' : hex;
    final bytes = [for (var index = 0; index < padded.length; index += 2) int.parse(padded.substring(index, index + 2), radix: 16)];
    final content = bytes.first & 0x80 == 0 ? bytes : [0, ...bytes];
    return [0x02, content.length, ...content];
  }
}
