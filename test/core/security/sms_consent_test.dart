import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/security/sms_consent.dart';

void main() {
  test('reads a code of the expected length out of the message', () {
    expect(SmsConsent.codeIn('Your Salli code is 482915. It expires in 3 minutes.', 6), '482915');
  });

  test('ignores longer numbers and messages without a code', () {
    expect(SmsConsent.codeIn('Call 0771234567 for help.', 6), isNull);
    expect(SmsConsent.codeIn('Welcome to Salli.', 6), isNull);
  });
}
