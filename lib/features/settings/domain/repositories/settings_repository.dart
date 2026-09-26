import '../entities/app_theme_mode.dart';

abstract interface class SettingsRepository {
  AppThemeMode get themeMode;

  Stream<AppThemeMode> get themeModeChanges;

  Future<void> saveThemeMode(AppThemeMode mode);
}
