import 'dart:math';

abstract final class IdGenerator {
  static const int defaultBytes = 16;

  static final Random _random = Random.secure();

  static String next({int bytes = defaultBytes}) => [for (var index = 0; index < bytes; index++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
}
