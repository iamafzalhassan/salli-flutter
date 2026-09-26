import 'package:get_it/get_it.dart';

import '../../features/banks/data/datasources/banks_remote_data_source.dart';
import '../../features/banks/data/repositories/banks_repository_impl.dart';
import '../../features/banks/domain/repositories/banks_repository.dart';
import '../../features/banks/domain/usecases/delete_bank_payee.dart';
import '../../features/banks/domain/usecases/get_bank_branches.dart';
import '../../features/banks/domain/usecases/get_bank_payees.dart';
import '../../features/banks/domain/usecases/get_banks.dart';
import '../../features/banks/domain/usecases/lookup_bank_account.dart';
import '../../features/banks/domain/usecases/save_bank_payee.dart';
import '../../features/banks/presentation/cubits/bank_payees_cubit.dart';
import '../../features/banks/presentation/cubits/new_bank_account_cubit.dart';

void registerBanksModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => BanksRemoteDataSource(injector()))
    ..registerLazySingleton<BanksRepository>(() => BanksRepositoryImpl(injector()))
    ..registerLazySingleton(() => DeleteBankPayee(injector()))
    ..registerLazySingleton(() => GetBankBranches(injector()))
    ..registerLazySingleton(() => GetBankPayees(injector()))
    ..registerLazySingleton(() => GetBanks(injector()))
    ..registerLazySingleton(() => LookupBankAccount(injector()))
    ..registerLazySingleton(() => SaveBankPayee(injector()))
    ..registerFactory(() => BankPayeesCubit(injector(), injector()))
    ..registerFactory(() => NewBankAccountCubit(injector(), injector(), injector(), injector()));
}
