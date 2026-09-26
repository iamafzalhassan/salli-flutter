import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/security/pin_policy.dart';

void main() {
  group('PinPolicy.isWeak', () {
    for (final pin in ['000000', '999999', '123456', '654321', '234567', '876543', '121212', '909090', '123123', '707707']) {
      test('flags $pin', () => expect(PinPolicy.isWeak(pin), isTrue));
    }

    for (final pin in ['482915', '135790', '102938', '112358', '789012', '590321']) {
      test('accepts $pin', () => expect(PinPolicy.isWeak(pin), isFalse));
    }
  });
}
