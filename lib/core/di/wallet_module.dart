import 'package:get_it/get_it.dart';

import '../../features/wallet/data/datasources/wallet_remote_data_source.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/data/statement/statement_document.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/export_statement.dart';
import '../../features/wallet/domain/usecases/get_insights.dart';
import '../../features/wallet/domain/usecases/get_transaction.dart';
import '../../features/wallet/domain/usecases/get_transactions.dart';
import '../../features/wallet/domain/usecases/get_wallet.dart';
import '../../features/wallet/domain/usecases/report_problem.dart';
import '../../features/wallet/domain/usecases/watch_wallet_changes.dart';
import '../../features/wallet/presentation/cubits/activity_cubit.dart';
import '../../features/wallet/presentation/cubits/home_cubit.dart';
import '../../features/wallet/presentation/cubits/insights_cubit.dart';
import '../../features/wallet/presentation/cubits/transaction_detail_cubit.dart';

void registerWalletModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => WalletRemoteDataSource(injector()))
    ..registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(injector(), const StatementDocument(), injector()))
    ..registerLazySingleton(() => ExportStatement(injector(), injector()))
    ..registerLazySingleton(() => GetInsights(injector()))
    ..registerLazySingleton(() => GetTransaction(injector()))
    ..registerLazySingleton(() => GetTransactions(injector()))
    ..registerLazySingleton(() => GetWallet(injector()))
    ..registerLazySingleton(() => ReportProblem(injector()))
    ..registerLazySingleton(() => WatchWalletChanges(injector()))
    ..registerFactory(() => ActivityCubit(injector(), injector(), injector(), injector()))
    ..registerFactory(() => HomeCubit(injector(), injector(), injector(), injector(), injector(), injector(), injector()))
    ..registerFactory(() => InsightsCubit(injector()))
    ..registerFactoryParam<TransactionDetailCubit, String, void>((id, _) => TransactionDetailCubit(id, injector(), injector()));
}
