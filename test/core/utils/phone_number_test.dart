import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/mobile_operator.dart';
import 'package:salli/core/utils/phone_number.dart';

void main() {
  group('PhoneNumber.tryParse', () {
    for (final input in ['0771234567', '771234567', '94771234567', '+94771234567', '+94 77 123 4567', '0094771234567', '077-123-4567']) {
      test('accepts $input', () => expect(PhoneNumber.tryParse(input)?.e164, '+94771234567'));
    }

    for (final input in ['0731234567', '0791234567', '0112345678', '07712345', '077123456789', '', 'phone']) {
      test('rejects "$input"', () => expect(PhoneNumber.tryParse(input), isNull));
    }
  });

  group('PhoneNumber.parse', () {
    test('returns the number for a valid input', () => expect(PhoneNumber.parse('+94771234567').e164, '+94771234567'));

    test('throws a FormatException for an invalid input', () => expect(() => PhoneNumber.parse('0731234567'), throwsFormatException));

    test('the longest pasted form fits the digit limit', () => expect(PhoneNumber.tryParse('94771234567'.substring(0, PhoneNumber.maxInputDigits)), isNotNull));
  });

  group('PhoneNumber', () {
    test('displays the local grouping', () => expect(PhoneNumber.tryParse('+94771234567')!.display, '077 123 4567'));

    test('resolves the carrier from the prefix', () {
      expect(PhoneNumber.tryParse('0712345678')!.carrier, MobileOperator.mobitel);
      expect(PhoneNumber.tryParse('0721234567')!.carrier, MobileOperator.hutch);
      expect(PhoneNumber.tryParse('0751234567')!.carrier, MobileOperator.airtel);
      expect(PhoneNumber.tryParse('0761234567')!.carrier, MobileOperator.dialog);
    });
  });
}
