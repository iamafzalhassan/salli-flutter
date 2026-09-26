import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/amount_input.dart';
import 'package:salli/core/utils/money.dart';

void main() {
  AmountInput type(String keys) {
    var input = const AmountInput();
    for (final key in keys.split('')) {
      input = switch (key) {
        '.' => input.addDecimalPoint(),
        '<' => input.backspace(),
        _ => input.append(int.parse(key)),
      };
    }
    return input;
  }

  group('AmountInput', () {
    test('of fills the keypad from a money value', () {
      expect(AmountInput.of(const Money(125050)).raw, '1250.50');
      expect(AmountInput.of(const Money.rupees(500)).raw, '500');
      expect(AmountInput.of(const Money(125005)).money, const Money(125005));
    });

    test('starts empty and shows zero', () {
      expect(const AmountInput().display, '0');
      expect(const AmountInput().money, Money.zero);
    });

    test('groups the whole rupees as you type', () => expect(type('1250000').display, '1,250,000'));

    test('keeps up to two decimals', () {
      final input = type('1250.509');
      expect(input.display, '1,250.50');
      expect(input.money, const Money(125050));
    });

    test('a leading decimal point becomes zero point', () => expect(type('.5').raw, '0.5'));

    test('ignores a second decimal point', () => expect(type('1.2.3').raw, '1.23'));

    test('replaces a leading zero', () => expect(type('05').raw, '5'));

    test('caps the whole part at nine digits', () => expect(type('1234567890').raw, '123456789'));

    test('backspace removes the last key', () => expect(type('12.5<<').raw, '12'));

    test('a trailing decimal point still parses', () => expect(type('12.').money, const Money(1200)));
  });
}
