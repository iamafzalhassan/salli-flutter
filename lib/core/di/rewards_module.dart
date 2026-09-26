import 'package:get_it/get_it.dart';

import '../../features/rewards/data/datasources/rewards_remote_data_source.dart';
import '../../features/rewards/data/repositories/rewards_repository_impl.dart';
import '../../features/rewards/domain/repositories/rewards_repository.dart';
import '../../features/rewards/domain/usecases/claim_referral.dart';
import '../../features/rewards/domain/usecases/get_offers.dart';
import '../../features/rewards/domain/usecases/get_rewards.dart';
import '../../features/rewards/domain/usecases/redeem_points.dart';
import '../../features/rewards/domain/usecases/reveal_scratch_card.dart';
import '../../features/rewards/presentation/cubits/rewards_cubit.dart';

void registerRewardsModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => RewardsRemoteDataSource(injector()))
    ..registerLazySingleton<RewardsRepository>(() => RewardsRepositoryImpl(injector(), injector()))
    ..registerLazySingleton(() => ClaimReferral(injector()))
    ..registerLazySingleton(() => GetOffers(injector()))
    ..registerLazySingleton(() => GetRewards(injector()))
    ..registerLazySingleton(() => RedeemPoints(injector()))
    ..registerLazySingleton(() => RevealScratchCard(injector()))
    ..registerFactory(() => RewardsCubit(injector(), injector(), injector(), injector(), injector()));
}
