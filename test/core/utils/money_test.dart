import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/money.dart';

void main() {
  group('Money', () {
    test('rupees converts to cents', () => expect(const Money.rupees(1250).cents, 125000));

    test('split gives the remainder to the first shares so they sum to the total', () {
      final shares = const Money(1000).split(3);
      expect(shares, const [Money(334), Money(333), Money(333)]);
      expect(shares.fold<Money>(Money.zero, (sum, share) => sum + share), const Money(1000));
    });

    test('split keeps a negative total exact', () {
      final shares = const Money(-1000).split(3);
      expect(shares, const [Money(-334), Money(-333), Money(-333)]);
      expect(shares.fold<Money>(Money.zero, (sum, share) => sum + share), const Money(-1000));
    });

    test('split rejects zero parts', () => expect(() => const Money(100).split(0), throwsArgumentError));

    test('rupeePart and centPart ignore the sign', () {
      const money = Money(-125050);
      expect(money.rupeePart, 1250);
      expect(money.centPart, 50);
    });

    test('comparison operators follow cents', () {
      expect(const Money(100) > const Money(99), isTrue);
      expect(const Money(100) <= const Money(100), isTrue);
      expect(const Money(-1) < Money.zero, isTrue);
    });
  });
}
