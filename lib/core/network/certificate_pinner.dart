import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class CertificatePinner {
  static const int _constructedContext = 0xA0;
  static const int _fieldsBeforeKey = 5;
  static const int _lengthMask = 0x7f;
  static const int _longForm = 0x80;

  final Set<String> pins;

  const CertificatePinner(this.pins);

  bool get isArmed => pins.isNotEmpty;

  void attach(Dio dio) {
    if (!isArmed) return;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()..badCertificateCallback = (_, _, _) => false,
      validateCertificate: (certificate, host, port) => certificate != null && pins.contains(spkiHash(certificate.der)),
    );
  }

  static String? spkiHash(List<int> der) {
    final key = subjectPublicKeyInfo(der);
    return key == null ? null : base64Encode(sha256.convert(key).bytes);
  }

  static List<int>? subjectPublicKeyInfo(List<int> der) {
    try {
      final certificate = _element(der, 0);
      final certificateBody = _element(der, certificate.contentStart);
      var offset = certificateBody.contentStart;
      if (der[offset] == _constructedContext) offset = _element(der, offset).end;
      for (var field = 0; field < _fieldsBeforeKey; field++) {
        offset = _element(der, offset).end;
      }
      final key = _element(der, offset);
      return key.end > der.length ? null : der.sublist(offset, key.end);
    } on RangeError {
      return null;
    }
  }

  static ({int contentStart, int end}) _element(List<int> der, int offset) {
    var length = der[offset + 1];
    var contentStart = offset + 2;
    if (length & _longForm != 0) {
      final count = length & _lengthMask;
      length = 0;
      for (var index = 0; index < count; index++) {
        length = (length << 8) | der[contentStart + index];
      }
      contentStart += count;
    }
    return (contentStart: contentStart, end: contentStart + length);
  }
}
