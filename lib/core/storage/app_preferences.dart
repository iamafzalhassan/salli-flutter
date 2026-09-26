import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _themeModeKey = 'theme_mode';

  static const Set<String> _keys = {_onboardingCompleteKey, _themeModeKey};

  final SharedPreferencesWithCache _preferences;

  const AppPreferences(this._preferences);

  bool get isOnboardingComplete => _preferences.getBool(_onboardingCompleteKey) ?? false;

  String? get themeMode => _preferences.getString(_themeModeKey);

  static Future<AppPreferences> load() async => AppPreferences(await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions(allowList: _keys)));

  Future<void> setOnboardingComplete() => _preferences.setBool(_onboardingCompleteKey, true);

  Future<void> setThemeMode(String value) => _preferences.setString(_themeModeKey, value);
}
