import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

class SaveThemeMode {
  final SettingsRepository _repository;

  const SaveThemeMode(this._repository);

  Future<void> call(AppThemeMode mode) => _repository.saveThemeMode(mode);
}
