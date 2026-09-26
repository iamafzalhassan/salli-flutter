import 'package:get_it/get_it.dart';

import '../../features/security/data/datasources/security_remote_data_source.dart';
import '../../features/security/data/repositories/security_repository_impl.dart';
import '../../features/security/domain/repositories/security_repository.dart';
import '../../features/security/domain/usecases/change_pin.dart';
import '../../features/security/domain/usecases/get_security_events.dart';
import '../../features/security/domain/usecases/get_trusted_devices.dart';
import '../../features/security/presentation/cubits/change_pin_cubit.dart';
import '../../features/security/presentation/cubits/security_cubit.dart';

void registerSecurityModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => SecurityRemoteDataSource(injector()))
    ..registerLazySingleton<SecurityRepository>(() => SecurityRepositoryImpl(injector(), injector()))
    ..registerLazySingleton(() => ChangePin(injector()))
    ..registerLazySingleton(() => GetSecurityEvents(injector()))
    ..registerLazySingleton(() => GetTrustedDevices(injector()))
    ..registerFactory(() => ChangePinCubit(injector()))
    ..registerFactory(() => SecurityCubit(injector(), injector()));
}
