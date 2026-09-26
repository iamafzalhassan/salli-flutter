abstract final class PatternCache {
  static final Map<String, RegExp> _patterns = {};

  static bool matches(String pattern, String input) => (_patterns[pattern] ??= RegExp(pattern)).hasMatch(input);
}
