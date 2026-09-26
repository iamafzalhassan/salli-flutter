import 'package:get_it/get_it.dart';

import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/presentation/cubits/profile_cubit.dart';

void registerProfileModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => ProfileRemoteDataSource(injector()))
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(injector()))
    ..registerLazySingleton(() => GetProfile(injector()))
    ..registerFactory(() => ProfileCubit(injector(), injector(), injector(), injector(), injector(), injector(), injector()));
}
