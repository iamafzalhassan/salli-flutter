import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

class WatchThemeMode {
  final SettingsRepository _repository;

  const WatchThemeMode(this._repository);

  Stream<AppThemeMode> call() => _repository.themeModeChanges;
}
