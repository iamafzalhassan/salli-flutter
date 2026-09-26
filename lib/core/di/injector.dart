import 'package:get_it/get_it.dart';

import '../router/app_router.dart';
import 'account_module.dart';
import 'auth_module.dart';
import 'banks_module.dart';
import 'bills_module.dart';
import 'cards_module.dart';
import 'core_module.dart';
import 'funding_module.dart';
import 'notifications_module.dart';
import 'onboarding_module.dart';
import 'payments_module.dart';
import 'profile_module.dart';
import 'reload_module.dart';
import 'requests_module.dart';
import 'rewards_module.dart';
import 'security_module.dart';
import 'settings_module.dart';
import 'wallet_module.dart';

final GetIt injector = GetIt.instance;

Future<void> configureDependencies() async {
  await registerCoreModule(injector);
  registerAccountModule(injector);
  registerAuthModule(injector);
  registerBanksModule(injector);
  registerBillsModule(injector);
  registerCardsModule(injector);
  registerFundingModule(injector);
  registerNotificationsModule(injector);
  registerOnboardingModule(injector);
  registerPaymentsModule(injector);
  registerProfileModule(injector);
  registerReloadModule(injector);
  registerRequestsModule(injector);
  registerRewardsModule(injector);
  registerSecurityModule(injector);
  registerSettingsModule(injector);
  registerWalletModule(injector);
  injector.registerSingleton(AppRouter(injector(), injector(), injector, injector(), injector()));
}
