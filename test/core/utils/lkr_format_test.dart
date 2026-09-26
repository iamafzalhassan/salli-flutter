import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/lkr_format.dart';
import 'package:salli/core/utils/money.dart';

void main() {
  group('LkrFormat.amount', () {
    test('groups thousands and always shows two decimals', () => expect(LkrFormat.amount(const Money(123456789)), '1,234,567.89'));

    test('pads small cent values', () => expect(LkrFormat.amount(const Money(5)), '0.05'));

    test('marks negatives with a minus sign', () => expect(LkrFormat.amount(const Money(-125050)), '−1,250.50'));
  });

  group('LkrFormat.withSymbol', () {
    test('puts the sign before the symbol', () => expect(LkrFormat.withSymbol(const Money(-125000), 'Rs.'), '−Rs. 1,250.00'));

    test('shows no sign for positives', () => expect(LkrFormat.withSymbol(const Money(99900), 'Rs.'), 'Rs. 999.00'));
  });

  group('LkrFormat.signed', () {
    test('marks credits with a plus sign', () => expect(LkrFormat.signed(const Money(99900), 'Rs.'), '+Rs. 999.00'));

    test('marks debits with a minus sign', () => expect(LkrFormat.signed(const Money(-99900), 'Rs.'), '−Rs. 999.00'));
  });

  group('LkrFormat.parse', () {
    test('reads whole rupees', () => expect(LkrFormat.parse('100'), const Money(10000)));

    test('reads grouped input with one decimal', () => expect(LkrFormat.parse('1,250.5'), const Money(125050)));

    test('reads a trailing decimal point', () => expect(LkrFormat.parse('12.'), const Money(1200)));

    test('rejects more than two decimals', () => expect(LkrFormat.parse('12.345'), isNull));

    test('rejects text', () => expect(LkrFormat.parse('abc'), isNull));

    test('rejects negatives', () => expect(LkrFormat.parse('-5'), isNull));
  });
}
