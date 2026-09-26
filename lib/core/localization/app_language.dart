import 'dart:ui';

enum AppLanguage {
  english('en'),
  sinhala('si'),
  tamil('ta');

  static const String translationsPath = 'assets/translations';

  final String code;

  const AppLanguage(this.code);

  static List<Locale> get locales => [for (final language in values) language.locale];

  Locale get locale => Locale(code);

  static AppLanguage fromLocale(Locale locale) => values.firstWhere((language) => language.code == locale.languageCode, orElse: () => english);
}
