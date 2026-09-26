import 'package:get_it/get_it.dart';

import '../../features/requests/data/datasources/requests_remote_data_source.dart';
import '../../features/requests/data/repositories/requests_repository_impl.dart';
import '../../features/requests/domain/entities/requests_tab.dart';
import '../../features/requests/domain/repositories/requests_repository.dart';
import '../../features/requests/domain/usecases/cancel_request.dart';
import '../../features/requests/domain/usecases/create_request.dart';
import '../../features/requests/domain/usecases/create_split.dart';
import '../../features/requests/domain/usecases/decline_request.dart';
import '../../features/requests/domain/usecases/get_requests.dart';
import '../../features/requests/domain/usecases/get_splits.dart';
import '../../features/requests/domain/usecases/remind_request.dart';
import '../../features/requests/presentation/cubits/pay_link_cubit.dart';
import '../../features/requests/presentation/cubits/request_money_cubit.dart';
import '../../features/requests/presentation/cubits/requests_cubit.dart';
import '../../features/requests/presentation/cubits/split_cubit.dart';

void registerRequestsModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => RequestsRemoteDataSource(injector()))
    ..registerLazySingleton<RequestsRepository>(() => RequestsRepositoryImpl(injector()))
    ..registerLazySingleton(() => CancelRequest(injector()))
    ..registerLazySingleton(() => CreateRequest(injector()))
    ..registerLazySingleton(() => CreateSplit(injector()))
    ..registerLazySingleton(() => DeclineRequest(injector()))
    ..registerLazySingleton(() => GetRequests(injector()))
    ..registerLazySingleton(() => GetSplits(injector()))
    ..registerLazySingleton(() => RemindRequest(injector()))
    ..registerFactory(() => RequestMoneyCubit(injector(), injector(), injector(), injector()))
    ..registerFactory(() => SplitCubit(injector(), injector(), injector()))
    ..registerFactoryParam<RequestsCubit, RequestsTab?, void>((tab, _) => RequestsCubit(injector(), injector(), injector(), injector(), injector(), tab: tab ?? RequestsTab.incoming))
    ..registerFactoryParam<PayLinkCubit, Map<String, String>, void>((query, _) => PayLinkCubit(query, injector()));
}
