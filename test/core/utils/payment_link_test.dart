import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/core/utils/payment_link.dart';
import 'package:salli/core/utils/phone_number.dart';

void main() {
  final phone = PhoneNumber.tryParse('0771234567')!;

  test('builds a salli link that reads back the same way', () {
    final uri = Uri.parse(PaymentLink.build(amount: const Money(125050), note: 'Lunch & tea', phone: phone));
    expect(uri.scheme, PaymentLink.scheme);
    expect(uri.host, PaymentLink.host);
    expect(uri.path, PaymentLink.path);
    final link = PaymentLink.parse(uri.queryParameters)!;
    expect(link.phone, phone);
    expect(link.amount, const Money(125050));
    expect(link.note, 'Lunch & tea');
  });

  test('a link may leave the amount open', () {
    final link = PaymentLink.parse(Uri.parse(PaymentLink.build(phone: phone)).queryParameters)!;
    expect(link.amount, isNull);
    expect(link.note, isNull);
  });

  test('rejects a link without a Sri Lankan mobile number', () => expect(PaymentLink.parse(const {'to': '+15550100'}), isNull));

  test('rejects a zero or malformed amount', () {
    expect(PaymentLink.parse(const {'amount': '0', 'to': '+94771234567'}), isNull);
    expect(PaymentLink.parse(const {'amount': '12.5', 'to': '+94771234567'}), isNull);
  });

  test('shortens an overlong note', () => expect(PaymentLink.parse({'note': 'x' * 100, 'to': '+94771234567'})!.note, hasLength(PaymentLink.maxNoteLength)));
}
