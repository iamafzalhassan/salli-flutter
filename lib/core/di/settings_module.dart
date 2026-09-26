import 'package:get_it/get_it.dart';

import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_theme_mode.dart';
import '../../features/settings/domain/usecases/save_theme_mode.dart';
import '../../features/settings/domain/usecases/watch_theme_mode.dart';
import '../../features/settings/presentation/cubits/appearance_cubit.dart';

void registerSettingsModule(GetIt injector) {
  injector
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(injector()))
    ..registerLazySingleton(() => GetThemeMode(injector()))
    ..registerLazySingleton(() => SaveThemeMode(injector()))
    ..registerLazySingleton(() => WatchThemeMode(injector()))
    ..registerLazySingleton(() => AppearanceCubit(injector(), injector()));
}
