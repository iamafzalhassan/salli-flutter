import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/network/certificate_pinner.dart';

void main() {
  const publicKeyInfo = [0x30, 0x03, 0xAA, 0xBB, 0xCC];
  const certificateBody = [0xA0, 0x03, 0x02, 0x01, 0x02, 0x02, 0x01, 0x01, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, 0x30, 0x00, ...publicKeyInfo];
  const certificate = [0x30, 0x81, 0x1B, 0x30, 0x15, ...certificateBody, 0x30, 0x00, 0x03, 0x00];

  test('finds the subject public key info after the version, serial, issuer, validity and subject', () {
    expect(CertificatePinner.subjectPublicKeyInfo(certificate), publicKeyInfo);
  });

  test('pins on the SHA-256 of the public key info', () {
    expect(CertificatePinner.spkiHash(certificate), base64Encode(sha256.convert(publicKeyInfo).bytes));
  });

  test('rejects a truncated certificate', () {
    expect(CertificatePinner.spkiHash(certificate.sublist(0, 12)), isNull);
  });

  test('is armed only with at least one pin', () {
    expect(const CertificatePinner({}).isArmed, isFalse);
    expect(const CertificatePinner({'pin'}).isArmed, isTrue);
  });
}
