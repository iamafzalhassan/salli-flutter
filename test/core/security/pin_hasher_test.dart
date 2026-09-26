import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/security/pin_hasher.dart';

void main() {
  String hex(List<int> bytes) => bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  group('PinHasher.derive matches the PBKDF2-HMAC-SHA256 reference vectors', () {
    test('one iteration', () => expect(hex(PinHasher.derive(utf8.encode('password'), utf8.encode('salt'), 1, 32)), '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b'));

    test('two iterations', () => expect(hex(PinHasher.derive(utf8.encode('password'), utf8.encode('salt'), 2, 32)), 'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43'));

    test('4096 iterations', () => expect(hex(PinHasher.derive(utf8.encode('password'), utf8.encode('salt'), 4096, 32)), 'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a'));

    test('output longer than one block', () {
      final derived = PinHasher.derive(utf8.encode('passwordPASSWORDpassword'), utf8.encode('saltSALTsaltSALTsaltSALTsaltSALTsalt'), 4096, 40);
      expect(hex(derived), '348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c4e2a1fb8dd53e1c635518c7dac47e9');
    });
  });

  group('PinHasher.hash', () {
    final salt = base64Encode(List<int>.filled(16, 7));

    test('is deterministic for the same PIN and salt', () async => expect(await const PinHasher().hash('482915', salt), await const PinHasher().hash('482915', salt)));

    test('produces a 32 byte key', () async => expect(base64Decode(await const PinHasher().hash('482915', salt)), hasLength(PinHasher.keyLength)));

    test('changes with the salt', () async => expect(await const PinHasher().hash('482915', salt), isNot(await const PinHasher().hash('482915', base64Encode(List<int>.filled(16, 8))))));
  });
}
