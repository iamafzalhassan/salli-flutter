import 'package:get_it/get_it.dart';

import '../../features/account/data/datasources/account_remote_data_source.dart';
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/account/domain/usecases/get_limits.dart';
import '../../features/account/domain/usecases/get_verification.dart';
import '../../features/account/domain/usecases/submit_kyc.dart';
import '../../features/account/presentation/cubits/account_cubit.dart';
import '../../features/account/presentation/cubits/kyc_cubit.dart';
import '../../features/account/presentation/cubits/profile_setup_cubit.dart';
import '../../features/profile/domain/usecases/update_profile.dart';

void registerAccountModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => AccountRemoteDataSource(injector()))
    ..registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(injector()))
    ..registerLazySingleton(() => GetLimits(injector()))
    ..registerLazySingleton(() => GetVerification(injector()))
    ..registerLazySingleton(() => SubmitKyc(injector()))
    ..registerLazySingleton(() => UpdateProfile(injector()))
    ..registerFactory(() => AccountCubit(injector(), injector(), injector()))
    ..registerFactory(() => KycCubit(injector()))
    ..registerFactory(() => ProfileSetupCubit(injector(), injector()));
}
