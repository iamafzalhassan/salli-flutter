import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

class PinHasher {
  static const int iterations = 100000;
  static const int keyLength = 32;

  const PinHasher();

  Future<String> hash(String pin, String salt) => Isolate.run(() => base64Encode(derive(utf8.encode(pin), base64Decode(salt), iterations, keyLength)));

  static List<int> derive(List<int> password, List<int> salt, int iterations, int length) {
    final hmac = Hmac(sha256, password);
    final output = <int>[];
    for (var block = 1; output.length < length; block++) {
      var round = hmac.convert([...salt, block >> 24 & 0xff, block >> 16 & 0xff, block >> 8 & 0xff, block & 0xff]).bytes;
      final accumulated = List<int>.of(round);
      for (var iteration = 1; iteration < iterations; iteration++) {
        round = hmac.convert(round).bytes;
        for (var index = 0; index < accumulated.length; index++) {
          accumulated[index] ^= round[index];
        }
      }
      output.addAll(accumulated);
    }
    return output.sublist(0, length);
  }
}
