import 'package:get_it/get_it.dart';

import '../../features/reload/data/datasources/reload_remote_data_source.dart';
import '../../features/reload/data/repositories/reload_repository_impl.dart';
import '../../features/reload/domain/repositories/reload_repository.dart';
import '../../features/reload/domain/usecases/get_recent_reloads.dart';
import '../../features/reload/domain/usecases/get_reload_catalog.dart';
import '../../features/reload/presentation/cubits/reload_cubit.dart';

void registerReloadModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => ReloadRemoteDataSource(injector()))
    ..registerLazySingleton<ReloadRepository>(() => ReloadRepositoryImpl(injector()))
    ..registerLazySingleton(() => GetRecentReloads(injector()))
    ..registerLazySingleton(() => GetReloadCatalog(injector()))
    ..registerFactory(() => ReloadCubit(injector(), injector(), injector()));
}
