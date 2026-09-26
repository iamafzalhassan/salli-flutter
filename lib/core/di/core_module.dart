import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../events/app_events.dart';
import '../mock/mock_api_interceptor.dart';
import '../mock/mock_modules.dart';
import '../mock/mock_server.dart';
import '../mock/mock_sms_inbox.dart';
import '../mock/mock_store.dart';
import '../network/api_client.dart';
import '../network/certificate_pinner.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/reachability_interceptor.dart';
import '../network/interceptors/signing_interceptor.dart';
import '../network/network_status.dart';
import '../network/token_refresher.dart';
import '../security/app_lock.dart';
import '../security/approver.dart';
import '../security/biometric_key_store.dart';
import '../security/biometric_vault.dart';
import '../security/device_identity.dart';
import '../security/device_key_store.dart';
import '../security/pin_credential.dart';
import '../security/pin_hasher.dart';
import '../security/runtime_guard.dart';
import '../security/screen_protection.dart';
import '../security/session_store.dart';
import '../storage/app_preferences.dart';
import '../storage/local_database.dart';
import '../storage/secure_store.dart';

Future<void> registerCoreModule(GetIt injector) async {
  final config = AppConfig.fromEnvironment();
  final secureStore = SecureStore.device();
  final database = LocalDatabase(secureStore);
  final sessionStore = SessionStore(secureStore);
  final deviceIdentity = DeviceIdentity(const DeviceKeyStore(), secureStore);
  final options = BaseOptions(baseUrl: config.baseUrl, connectTimeout: AppConfig.connectTimeout, contentType: Headers.jsonContentType, receiveTimeout: AppConfig.receiveTimeout, responseType: ResponseType.json);
  final dio = Dio(options);
  final refreshDio = Dio(options);
  final signingInterceptor = SigningInterceptor(deviceIdentity, sessionStore);
  final tokenRefresher = TokenRefresher(refreshDio, sessionStore);
  final networkStatus = NetworkStatus(() => NetworkStatus.canReach(Uri.parse(config.baseUrl).host));
  final pinner = CertificatePinner(config.environment.pins);
  await sessionStore.load();
  pinner
    ..attach(dio)
    ..attach(refreshDio);
  refreshDio.interceptors.add(signingInterceptor);
  dio.interceptors.addAll([AuthInterceptor(dio, sessionStore, tokenRefresher), signingInterceptor, ReachabilityInterceptor(networkStatus)]);
  injector
    ..registerSingleton(config)
    ..registerSingleton(secureStore)
    ..registerSingleton(database)
    ..registerSingleton(sessionStore)
    ..registerSingleton(deviceIdentity)
    ..registerSingleton(tokenRefresher)
    ..registerSingleton(networkStatus)
    ..registerSingleton(AppEvents())
    ..registerSingleton(AppLock(sessionStore))
    ..registerSingleton(RuntimeGuard(sessionStore))
    ..registerSingleton(ScreenProtection())
    ..registerSingleton(await AppPreferences.load())
    ..registerLazySingleton(() => const PinHasher())
    ..registerLazySingleton(() => PinCredential(injector(), injector()))
    ..registerLazySingleton(() => BiometricVault(const BiometricKeyStore(), injector()))
    ..registerLazySingleton(() => Approver(injector(), injector()));
  if (config.usesMockApi) {
    final inbox = MockSmsInbox();
    final store = MockStore(await database.open(LocalDatabase.mockApiBox));
    final mockInterceptor = MockApiInterceptor(MockServer(mockModules(inbox, store), store));
    injector
      ..registerSingleton(inbox)
      ..registerSingleton(store);
    dio.interceptors.add(mockInterceptor);
    refreshDio.interceptors.add(mockInterceptor);
  }
  injector.registerSingleton(ApiClient(dio));
}
