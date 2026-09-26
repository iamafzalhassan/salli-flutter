import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/gender.dart';
import 'package:salli/core/utils/nic.dart';

void main() {
  group('Nic.tryParse legacy format', () {
    test('reads the birth date and a male day code', () {
      final nic = Nic.tryParse('853400937V')!;
      expect(nic.dateOfBirth, DateTime.utc(1985, 12, 5));
      expect(nic.gender, Gender.male);
      expect(nic.isLegacy, isTrue);
    });

    test('subtracts 500 for a female day code', () {
      final nic = Nic.tryParse('858400937V')!;
      expect(nic.dateOfBirth, DateTime.utc(1985, 12, 5));
      expect(nic.gender, Gender.female);
    });

    test('normalises a lowercase suffix and spaces', () => expect(Nic.tryParse(' 853400937v ')!.number, '853400937V'));

    test('accepts X as the suffix', () => expect(Nic.tryParse('853400937X'), isNotNull));

    test('accepts 29 February in a leap year', () => expect(Nic.tryParse('840600937V')!.dateOfBirth, DateTime.utc(1984, 2, 29)));

    test('rejects 29 February outside a leap year', () => expect(Nic.tryParse('850600937V'), isNull));
  });

  group('Nic.tryParse modern format', () {
    test('reads a male NIC', () {
      final nic = Nic.tryParse('200012345678')!;
      expect(nic.dateOfBirth, DateTime.utc(2000, 5, 2));
      expect(nic.gender, Gender.male);
      expect(nic.isLegacy, isFalse);
    });

    test('reads a female NIC', () {
      final nic = Nic.tryParse('199565012345')!;
      expect(nic.dateOfBirth, DateTime.utc(1995, 5, 29));
      expect(nic.gender, Gender.female);
    });

    test('rejects a future birth year', () => expect(Nic.tryParse('${DateTime.now().year + 1}12345678'), isNull));
  });

  group('Nic.tryParse invalid input', () {
    for (final input in ['850000937V', '853700937V', '858700937V', '12345', '85340093V', '8534009370', 'ABCDEFGHIJ']) {
      test('rejects $input', () => expect(Nic.tryParse(input), isNull));
    }
  });
}
