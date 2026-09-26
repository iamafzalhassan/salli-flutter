import 'package:get_it/get_it.dart';

import '../../features/bills/data/datasources/bills_remote_data_source.dart';
import '../../features/bills/data/repositories/bills_repository_impl.dart';
import '../../features/bills/domain/entities/bill_account_draft.dart';
import '../../features/bills/domain/repositories/bills_repository.dart';
import '../../features/bills/domain/usecases/cancel_bill_schedule.dart';
import '../../features/bills/domain/usecases/delete_saved_biller.dart';
import '../../features/bills/domain/usecases/get_bill_schedules.dart';
import '../../features/bills/domain/usecases/get_billers.dart';
import '../../features/bills/domain/usecases/get_saved_billers.dart';
import '../../features/bills/domain/usecases/inquire_bill.dart';
import '../../features/bills/domain/usecases/rename_saved_biller.dart';
import '../../features/bills/domain/usecases/save_biller.dart';
import '../../features/bills/domain/usecases/schedule_bill.dart';
import '../../features/bills/presentation/cubits/bill_account_cubit.dart';
import '../../features/bills/presentation/cubits/bills_cubit.dart';

void registerBillsModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => BillsRemoteDataSource(injector()))
    ..registerLazySingleton<BillsRepository>(() => BillsRepositoryImpl(injector(), injector()))
    ..registerLazySingleton(() => CancelBillSchedule(injector()))
    ..registerLazySingleton(() => DeleteSavedBiller(injector()))
    ..registerLazySingleton(() => GetBillers(injector()))
    ..registerLazySingleton(() => GetBillSchedules(injector()))
    ..registerLazySingleton(() => GetSavedBillers(injector()))
    ..registerLazySingleton(() => InquireBill(injector()))
    ..registerLazySingleton(() => RenameSavedBiller(injector()))
    ..registerLazySingleton(() => SaveBiller(injector()))
    ..registerLazySingleton(() => ScheduleBill(injector()))
    ..registerFactory(() => BillsCubit(injector(), injector(), injector(), injector(), injector(), injector(), injector()))
    ..registerFactoryParam<BillAccountCubit, BillAccountDraft, void>((draft, _) => BillAccountCubit(draft, injector(), injector()));
}
