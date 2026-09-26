import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/biometric_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/biometric_repository_impl.dart';
import '../../features/auth/domain/entities/otp_challenge.dart';
import '../../features/auth/domain/entities/otp_verification.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/biometric_repository.dart';
import '../../features/auth/domain/usecases/create_account.dart';
import '../../features/auth/domain/usecases/disable_biometrics.dart';
import '../../features/auth/domain/usecases/enable_biometrics.dart';
import '../../features/auth/domain/usecases/get_biometric_status.dart';
import '../../features/auth/domain/usecases/request_otp.dart';
import '../../features/auth/domain/usecases/reset_pin.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/unlock_app.dart';
import '../../features/auth/domain/usecases/verify_otp.dart';
import '../../features/auth/presentation/cubits/otp_cubit.dart';
import '../../features/auth/presentation/cubits/phone_cubit.dart';
import '../../features/auth/presentation/cubits/pin_cubit.dart';
import '../../features/auth/presentation/cubits/unlock_cubit.dart';

void registerAuthModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => AuthRemoteDataSource(injector()))
    ..registerLazySingleton(() => BiometricRemoteDataSource(injector()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(injector(), injector(), injector(), injector(), injector(), injector(), injector()))
    ..registerLazySingleton<BiometricRepository>(() => BiometricRepositoryImpl(injector(), injector(), injector()))
    ..registerLazySingleton(() => CreateAccount(injector()))
    ..registerLazySingleton(() => DisableBiometrics(injector()))
    ..registerLazySingleton(() => EnableBiometrics(injector()))
    ..registerLazySingleton(() => GetBiometricStatus(injector()))
    ..registerLazySingleton(() => RequestOtp(injector()))
    ..registerLazySingleton(() => ResetPin(injector()))
    ..registerLazySingleton(() => SignIn(injector()))
    ..registerLazySingleton(() => SignOut(injector()))
    ..registerLazySingleton(() => UnlockApp(injector()))
    ..registerLazySingleton(() => VerifyOtp(injector()))
    ..registerFactory(() => PhoneCubit(injector()))
    ..registerFactory(() => UnlockCubit(injector(), injector(), injector()))
    ..registerFactoryParam<OtpCubit, OtpChallenge, void>((challenge, _) => OtpCubit(challenge, injector(), injector()))
    ..registerFactoryParam<PinCubit, OtpVerification, void>((verification, _) => PinCubit(injector(), verification, injector(), injector()));
}
