import 'package:get_it/get_it.dart';

import '../../features/payments/data/datasources/payments_remote_data_source.dart';
import '../../features/payments/data/repositories/payments_repository_impl.dart';
import '../../features/payments/domain/entities/payment_draft.dart';
import '../../features/payments/domain/entities/recipient.dart';
import '../../features/payments/domain/repositories/payments_repository.dart';
import '../../features/payments/domain/usecases/assess_payment_risk.dart';
import '../../features/payments/domain/usecases/get_recent_payees.dart';
import '../../features/payments/domain/usecases/lookup_payee.dart';
import '../../features/payments/domain/usecases/resolve_code.dart';
import '../../features/payments/domain/usecases/send_payment.dart';
import '../../features/payments/presentation/cubits/amount_cubit.dart';
import '../../features/payments/presentation/cubits/my_qr_cubit.dart';
import '../../features/payments/presentation/cubits/review_cubit.dart';
import '../../features/payments/presentation/cubits/scan_cubit.dart';
import '../../features/payments/presentation/cubits/send_cubit.dart';

void registerPaymentsModule(GetIt injector) {
  injector
    ..registerLazySingleton(() => PaymentsRemoteDataSource(injector()))
    ..registerLazySingleton<PaymentsRepository>(() => PaymentsRepositoryImpl(injector(), injector(), injector()))
    ..registerLazySingleton(() => AssessPaymentRisk(injector()))
    ..registerLazySingleton(() => GetRecentPayees(injector()))
    ..registerLazySingleton(() => LookupPayee(injector()))
    ..registerLazySingleton(() => ResolveCode(injector()))
    ..registerLazySingleton(() => SendPayment(injector()))
    ..registerFactory(() => MyQrCubit(injector()))
    ..registerFactory(() => ScanCubit(injector()))
    ..registerFactory(() => SendCubit(injector(), injector()))
    ..registerFactoryParam<AmountCubit, Recipient, void>((recipient, _) => AmountCubit(injector(), injector(), recipient))
    ..registerFactoryParam<ReviewCubit, PaymentDraft, void>((draft, _) => ReviewCubit(injector(), injector(), draft, injector()));
}
