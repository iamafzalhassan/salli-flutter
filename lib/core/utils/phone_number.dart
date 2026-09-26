import 'package:equatable/equatable.dart';

import 'mobile_operator.dart';

class PhoneNumber extends Equatable {
  static const int maxInputDigits = 11;

  static const String countryCode = '+94';

  static final RegExp _nationalPattern = RegExp(r'^7[0124-8]\d{7}$');
  static final RegExp _separators = RegExp(r'[\s\-().]');

  final String national;

  const PhoneNumber._(this.national);

  String get display => '0${national.substring(0, 2)} ${national.substring(2, 5)} ${national.substring(5)}';
  String get e164 => '$countryCode$national';

  MobileOperator get carrier => MobileOperator.forPrefix(national.substring(0, 2))!;

  static PhoneNumber parse(String input) => tryParse(input) ?? (throw FormatException('Invalid phone number', input));

  static PhoneNumber? tryParse(String input) {
    final national = _nationalDigits(input.replaceAll(_separators, ''));
    return _nationalPattern.hasMatch(national) ? PhoneNumber._(national) : null;
  }

  static String _nationalDigits(String digits) {
    for (final prefix in const ['+94', '0094', '94', '0']) {
      if (digits.startsWith(prefix) && digits.length > prefix.length + 8) return digits.substring(prefix.length);
    }
    return digits;
  }

  @override
  List<Object?> get props => [national];
}
