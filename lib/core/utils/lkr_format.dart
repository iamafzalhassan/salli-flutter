import 'package:intl/intl.dart';

import 'money.dart';

abstract final class LkrFormat {
  static const String minusSign = '−';
  static const String plusSign = '+';

  static final NumberFormat _grouping = NumberFormat('#,##0', 'en_US');

  static final RegExp _input = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$');

  static Money? parse(String input) {
    final match = _input.firstMatch(input.replaceAll(',', '').trim());
    if (match == null) return null;
    final rupees = int.parse(match.group(1)!);
    final cents = int.parse((match.group(2) ?? '').padRight(2, '0'));
    return Money(rupees * Money.centsPerRupee + cents);
  }

  static String signed(Money money, String symbol) => '${money.isNegative ? minusSign : plusSign}$symbol ${amount(money.abs())}';

  static String withSymbol(Money money, String symbol) => '${money.isNegative ? minusSign : ''}$symbol ${amount(money.abs())}';

  static String amount(Money money) => '${money.isNegative ? minusSign : ''}${wholeRupees(money.rupeePart)}.${money.centPart.toString().padLeft(2, '0')}';

  static String wholeRupees(int rupees) => _grouping.format(rupees);
}
