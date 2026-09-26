import 'package:get_it/get_it.dart';

import '../../features/cards/data/datasources/cards_remote_data_source.dart';
import '../../features/cards/data/repositories/cards_repository_impl.dart';
import '../../features/cards/domain/repositories/cards_repository.dart';
import '../../features/cards/domain/usecases/freeze_card.dart';
import '../../features/cards/domain/usecases/get_card.dart';
import '../../features/cards/domain/usecases/get_card_transactions.dart';
import '../../features/cards/domain/usecases/make_test_purchase.dart';
import '../../features/cards/domain/usecases/reveal_card.dart';
import '../../features/cards/domain/usecases/set_card_limit.dart';
import '../../features/cards/presentation/cubits/card_cubit.dart';

void registerCardsModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => CardsRemoteDataSource(injector()))
    ..registerLazySingleton<CardsRepository>(() => CardsRepositoryImpl(injector(), injector()))
    ..registerLazySingleton(() => FreezeCard(injector()))
    ..registerLazySingleton(() => GetCard(injector()))
    ..registerLazySingleton(() => GetCardTransactions(injector()))
    ..registerLazySingleton(() => MakeTestPurchase(injector()))
    ..registerLazySingleton(() => RevealCard(injector()))
    ..registerLazySingleton(() => SetCardLimit(injector()))
    ..registerFactory(() => CardCubit(injector(), injector(), injector(), injector(), injector(), injector(), injector()));
}
