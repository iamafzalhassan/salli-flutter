abstract final class PinPolicy {
  static const int length = 6;

  static const Duration settleDelay = Duration(milliseconds: 180);

  static bool isWeak(String pin) => pin.split('').toSet().length == 1 || _isSequential(pin, 1) || _isSequential(pin, -1) || _repeats(pin, 2) || _repeats(pin, 3);

  static bool _isSequential(String pin, int step) {
    for (var index = 1; index < pin.length; index++) {
      if (pin.codeUnitAt(index) - pin.codeUnitAt(index - 1) != step) return false;
    }
    return true;
  }

  static bool _repeats(String pin, int chunk) => pin.length % chunk == 0 && pin == pin.substring(0, chunk) * (pin.length ~/ chunk);
}
