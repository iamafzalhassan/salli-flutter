import 'dart:async';

import '../../../../core/storage/app_preferences.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppPreferences _preferences;

  final StreamController<AppThemeMode> _themeModeChanges = StreamController<AppThemeMode>.broadcast();

  SettingsRepositoryImpl(this._preferences);

  @override
  AppThemeMode get themeMode => AppThemeMode.values.asNameMap()[_preferences.themeMode] ?? AppThemeMode.dark;

  @override
  Stream<AppThemeMode> get themeModeChanges => _themeModeChanges.stream;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    await _preferences.setThemeMode(mode.name);
    _themeModeChanges.add(mode);
  }
}
