import 'package:equatable/equatable.dart';

class Money extends Equatable implements Comparable<Money> {
  static const int centsPerRupee = 100;

  static const Money zero = Money(0);

  final int cents;

  const Money(this.cents);

  const Money.rupees(int rupees) : cents = rupees * centsPerRupee;

  bool get isNegative => cents < 0;
  bool get isPositive => cents > 0;
  bool get isZero => cents == 0;

  int get centPart => cents.abs() % centsPerRupee;
  int get rupeePart => cents.abs() ~/ centsPerRupee;

  Money operator +(Money other) => Money(cents + other.cents);

  Money operator -(Money other) => Money(cents - other.cents);

  bool operator <(Money other) => cents < other.cents;

  bool operator <=(Money other) => cents <= other.cents;

  bool operator >(Money other) => cents > other.cents;

  bool operator >=(Money other) => cents >= other.cents;

  Money abs() => Money(cents.abs());

  List<Money> split(int parts) {
    if (parts <= 0) throw ArgumentError.value(parts, 'parts', 'Must be positive');
    final share = cents ~/ parts;
    final remainder = cents.remainder(parts).abs();
    final step = cents.isNegative ? -1 : 1;
    return [for (var index = 0; index < parts; index++) Money(share + (index < remainder ? step : 0))];
  }

  @override
  List<Object?> get props => [cents];

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);
}
