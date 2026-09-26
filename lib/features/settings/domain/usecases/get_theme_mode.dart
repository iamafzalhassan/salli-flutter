import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

class GetThemeMode {
  final SettingsRepository _repository;

  const GetThemeMode(this._repository);

  AppThemeMode call() => _repository.themeMode;
}
