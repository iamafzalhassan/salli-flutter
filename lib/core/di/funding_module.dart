import 'package:get_it/get_it.dart';

import '../../features/funding/data/datasources/funding_remote_data_source.dart';
import '../../features/funding/data/repositories/funding_repository_impl.dart';
import '../../features/funding/domain/repositories/funding_repository.dart';
import '../../features/funding/domain/usecases/add_card.dart';
import '../../features/funding/domain/usecases/get_funding_sources.dart';
import '../../features/funding/domain/usecases/link_bank_account.dart';
import '../../features/funding/domain/usecases/remove_funding_source.dart';
import '../../features/funding/domain/usecases/verify_bank_link.dart';
import '../../features/funding/presentation/cubits/add_card_cubit.dart';
import '../../features/funding/presentation/cubits/funding_cubit.dart';
import '../../features/funding/presentation/cubits/link_bank_cubit.dart';

void registerFundingModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => FundingRemoteDataSource(injector()))
    ..registerLazySingleton<FundingRepository>(() => FundingRepositoryImpl(injector()))
    ..registerLazySingleton(() => AddCard(injector()))
    ..registerLazySingleton(() => GetFundingSources(injector()))
    ..registerLazySingleton(() => LinkBankAccount(injector()))
    ..registerLazySingleton(() => RemoveFundingSource(injector()))
    ..registerLazySingleton(() => VerifyBankLink(injector()))
    ..registerFactory(() => AddCardCubit(injector()))
    ..registerFactory(() => LinkBankCubit(injector(), injector(), injector(), injector()))
    ..registerFactoryParam<FundingCubit, bool, void>((isWithdrawal, _) => FundingCubit(injector(), injector(), isWithdrawal: isWithdrawal));
}
