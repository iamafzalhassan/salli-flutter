import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/lanka_qr.dart';
import 'package:salli/core/utils/money.dart';

void main() {
  String field(String tag, String value) => '$tag${value.length.toString().padLeft(2, '0')}$value';

  String withChecksum(String body) {
    final data = '${body}6304';
    return '$data${LankaQr.crc16(utf8.encode(data)).toRadixString(16).toUpperCase().padLeft(4, '0')}';
  }

  String merchantAccount({String guid = LankaQr.merchantGuid, String id = 'LKQR00000001'}) => field('26', '${field('00', guid)}${field('01', id)}');

  String payload({String account = '', String amount = '', String country = 'LK', String currency = '144', String name = 'Keells Super', String start = '000201'}) => withChecksum(
    [
      start,
      field('01', '11'),
      if (account.isEmpty) merchantAccount() else account,
      field('52', '5411'),
      field('53', currency),
      if (amount.isNotEmpty) field('54', amount),
      field('58', country),
      if (name.isNotEmpty) field('59', name),
      field('60', 'Colombo 07'),
    ].join(),
  );

  Matcher throwsIssue(LankaQrIssue issue) => throwsA(isA<LankaQrException>().having((exception) => exception.issue, 'issue', issue));

  const keells = LankaQr(accountId: 'LKQR00000001', categoryCode: '5411', city: 'Colombo 07', guid: LankaQr.merchantGuid, isDynamic: false, name: 'Keells Super');

  group('crc16', () {
    test('matches the CRC-16/CCITT-FALSE check value', () => expect(LankaQr.crc16(utf8.encode('123456789')), 0x29B1));

    test('is 0xFFFF for no input', () => expect(LankaQr.crc16(const []), 0xFFFF));
  });

  group('encode', () {
    test('writes the EMVCo header, LKR, Sri Lanka and a checksum last', () {
      final encoded = keells.encode();
      expect(encoded, startsWith('000201010211'));
      expect(encoded, contains('5303144'));
      expect(encoded, contains('5802LK'));
      expect(encoded, matches(RegExp(r'6304[0-9A-F]{4}$')));
    });

    test('marks a code with an amount as dynamic and writes the amount with two decimals', () {
      final encoded = const LankaQr.personal(amount: Money(125050), name: 'Fathima Rizna', phone: '+94704445566').encode();
      expect(encoded, contains('010212'));
      expect(encoded, contains('54071250.50'));
    });

    test('truncates names and cities to the EMVCo limits', () {
      final parsed = LankaQr.parse(const LankaQr(accountId: 'id', categoryCode: '5411', city: 'Sri Jayawardenepura Kotte', guid: LankaQr.merchantGuid, isDynamic: false, name: 'The Very Long Name Of A Grocery Store').encode());
      expect(parsed.name, hasLength(LankaQr.maxNameLength));
      expect(parsed.city, hasLength(LankaQr.maxCityLength));
    });
  });

  group('parse', () {
    test('reads back a static merchant code exactly', () => expect(LankaQr.parse(keells.encode()), keells));

    test('reads back a dynamic merchant code with its amount and reference', () {
      const code = LankaQr(accountId: 'LKQR00000003', amount: Money(82000), categoryCode: '4121', city: 'Colombo 03', guid: LankaQr.merchantGuid, isDynamic: true, name: 'PickMe', reference: 'PM58213');
      expect(LankaQr.parse(code.encode()), code);
    });

    test('reads back a personal code', () {
      final parsed = LankaQr.parse(const LankaQr.personal(amount: Money.rupees(500), name: 'Fathima Rizna', phone: '+94704445566').encode());
      expect(parsed.isPersonal, isTrue);
      expect(parsed.isDynamic, isTrue);
      expect(parsed.accountId, '+94704445566');
      expect(parsed.amount, const Money.rupees(500));
    });

    test('accepts whole-rupee and one-decimal amounts', () {
      expect(LankaQr.parse(payload(amount: '500')).amount, const Money(50000));
      expect(LankaQr.parse(payload(amount: '1250.5')).amount, const Money(125050));
    });

    test('ignores surrounding whitespace and a lowercase checksum', () {
      final encoded = payload(name: 'Arpico');
      final checksumAt = encoded.length - 4;
      expect(LankaQr.parse('  ${encoded.substring(0, checksumAt)}${encoded.substring(checksumAt).toLowerCase()}\n').name, 'Arpico');
    });

    test('reads a guid in any case', () => expect(LankaQr.parse(payload(account: merchantAccount(guid: 'LK.LANKAQR'))).guid, LankaQr.merchantGuid));

    test('rejects a code whose content was changed after it was printed', () {
      final tampered = keells.encode().replaceFirst('Keells Super', 'Keells Supar');
      expect(() => LankaQr.parse(tampered), throwsIssue(LankaQrIssue.checksum));
    });

    test('rejects a code without a checksum', () => expect(() => LankaQr.parse('000201010211'), throwsIssue(LankaQrIssue.format)));

    test('rejects text that is not a QR payload at all', () => expect(() => LankaQr.parse('https://example.com'), throwsIssue(LankaQrIssue.format)));

    test('rejects a payload that does not start with the format indicator', () => expect(() => LankaQr.parse(payload(start: '000202')), throwsIssue(LankaQrIssue.format)));

    test('rejects a field whose length runs past the end', () => expect(() => LankaQr.parse(withChecksum('0002015999Keells')), throwsIssue(LankaQrIssue.format)));

    test('rejects a currency other than LKR', () => expect(() => LankaQr.parse(payload(currency: '840')), throwsIssue(LankaQrIssue.currency)));

    test('rejects a country other than Sri Lanka', () => expect(() => LankaQr.parse(payload(country: 'IN')), throwsIssue(LankaQrIssue.country)));

    test('rejects a code without a merchant name', () => expect(() => LankaQr.parse(payload(name: '')), throwsIssue(LankaQrIssue.missingField)));

    test('rejects an account template from another scheme', () => expect(() => LankaQr.parse(payload(account: merchantAccount(guid: 'com.example.pay'))), throwsIssue(LankaQrIssue.missingField)));

    test('rejects a zero amount', () => expect(() => LankaQr.parse(payload(amount: '0.00')), throwsIssue(LankaQrIssue.format)));

    test('rejects an amount with three decimals', () => expect(() => LankaQr.parse(payload(amount: '10.505')), throwsIssue(LankaQrIssue.format)));
  });
}
