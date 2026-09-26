import 'package:equatable/equatable.dart';

import 'gender.dart';

class Nic extends Equatable {
  static const int femaleDayOffset = 500;
  static const int legacyCenturyBase = 1900;

  static const List<int> _monthLengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  static final RegExp _legacyPattern = RegExp(r'^(\d{2})(\d{3})\d{4}[VX]$');
  static final RegExp _modernPattern = RegExp(r'^(\d{4})(\d{3})\d{5}$');

  final String number;

  final DateTime dateOfBirth;

  final Gender gender;

  const Nic._({required this.number, required this.dateOfBirth, required this.gender});

  bool get isLegacy => number.length == 10;

  static Nic? tryParse(String input) {
    final number = input.replaceAll(' ', '').toUpperCase();
    final match = _legacyPattern.firstMatch(number) ?? _modernPattern.firstMatch(number);
    if (match == null) return null;
    final yearDigits = match.group(1)!;
    final year = yearDigits.length == 2 ? legacyCenturyBase + int.parse(yearDigits) : int.parse(yearDigits);
    final encodedDay = int.parse(match.group(2)!);
    final isFemale = encodedDay > femaleDayOffset;
    final dateOfBirth = _dateFromDayOfYear(year, isFemale ? encodedDay - femaleDayOffset : encodedDay);
    if (dateOfBirth == null) return null;
    return Nic._(dateOfBirth: dateOfBirth, gender: isFemale ? Gender.female : Gender.male, number: number);
  }

  static DateTime? _dateFromDayOfYear(int year, int day) {
    if (year < legacyCenturyBase || year > DateTime.now().year || day < 1 || day > 366) return null;
    var remaining = day;
    for (var month = 1; month <= _monthLengths.length; month++) {
      final length = _monthLengths[month - 1];
      if (remaining <= length) return month == 2 && remaining == 29 && !_isLeapYear(year) ? null : DateTime.utc(year, month, remaining);
      remaining -= length;
    }
    return null;
  }

  static bool _isLeapYear(int year) => year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  @override
  List<Object?> get props => [number];
}
