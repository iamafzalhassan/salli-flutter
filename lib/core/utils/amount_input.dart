import 'package:equatable/equatable.dart';

import 'lkr_format.dart';
import 'money.dart';

class AmountInput extends Equatable {
  static const int maxFractionDigits = 2;
  static const int maxWholeDigits = 9;

  static const String decimalPoint = '.';

  final String raw;

  const AmountInput([this.raw = '']);

  factory AmountInput.of(Money money) => AmountInput(money.centPart == 0 ? '${money.rupeePart}' : '${money.rupeePart}$decimalPoint${money.centPart.toString().padLeft(maxFractionDigits, '0')}');

  bool get hasDecimalPoint => raw.contains(decimalPoint);
  bool get isEmpty => raw.isEmpty;

  String get display => raw.isEmpty ? '0' : '${LkrFormat.wholeRupees(int.parse(_whole))}${hasDecimalPoint ? '$decimalPoint$_fraction' : ''}';
  String get _fraction => hasDecimalPoint ? raw.substring(raw.indexOf(decimalPoint) + 1) : '';
  String get _whole => hasDecimalPoint ? raw.substring(0, raw.indexOf(decimalPoint)) : raw;

  Money get money => raw.isEmpty ? Money.zero : LkrFormat.parse(raw) ?? Money.zero;

  AmountInput addDecimalPoint() => hasDecimalPoint ? this : AmountInput(raw.isEmpty ? '0$decimalPoint' : '$raw$decimalPoint');

  AmountInput append(int digit) {
    if (hasDecimalPoint) return _fraction.length >= maxFractionDigits ? this : AmountInput('$raw$digit');
    if (raw == '0') return AmountInput('$digit');
    return raw.length >= maxWholeDigits ? this : AmountInput('$raw$digit');
  }

  AmountInput backspace() => raw.isEmpty ? this : AmountInput(raw.substring(0, raw.length - 1));

  @override
  List<Object?> get props => [raw];
}
