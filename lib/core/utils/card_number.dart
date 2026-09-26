abstract final class CardNumber {
  static const int maxDigits = 19;
  static const int minDigits = 13;

  static final RegExp _digits = RegExp(r'^\d+$');

  static bool isValid(String number) => _digits.hasMatch(number) && number.length >= minDigits && number.length <= maxDigits && passesLuhn(number);

  static bool passesLuhn(String number) {
    var sum = 0;
    for (var index = 0; index < number.length; index++) {
      var digit = int.parse(number[number.length - 1 - index]);
      if (index.isOdd) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }
    return sum % 10 == 0;
  }
}
