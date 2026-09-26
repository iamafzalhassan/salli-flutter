import 'package:get_it/get_it.dart';

import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/check_onboarding_complete.dart';
import '../../features/onboarding/domain/usecases/complete_onboarding.dart';
import '../../features/onboarding/presentation/cubits/onboarding_cubit.dart';

void registerOnboardingModule(GetIt injector) {
  injector
    ..registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl(injector()))
    ..registerLazySingleton(() => CheckOnboardingComplete(injector()))
    ..registerLazySingleton(() => CompleteOnboarding(injector()))
    ..registerFactory(() => OnboardingCubit(injector()));
}
