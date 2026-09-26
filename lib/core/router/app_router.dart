import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/cubits/account_cubit.dart';
import '../../features/account/presentation/cubits/kyc_cubit.dart';
import '../../features/account/presentation/cubits/profile_setup_cubit.dart';
import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/kyc_page.dart';
import '../../features/account/presentation/pages/profile_setup_page.dart';
import '../../features/auth/domain/entities/otp_challenge.dart';
import '../../features/auth/domain/entities/otp_verification.dart';
import '../../features/auth/presentation/cubits/otp_cubit.dart';
import '../../features/auth/presentation/cubits/phone_cubit.dart';
import '../../features/auth/presentation/cubits/pin_cubit.dart';
import '../../features/auth/presentation/cubits/unlock_cubit.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/phone_page.dart';
import '../../features/auth/presentation/pages/pin_page.dart';
import '../../features/auth/presentation/pages/unlock_page.dart';
import '../../features/banks/presentation/cubits/bank_payees_cubit.dart';
import '../../features/banks/presentation/cubits/new_bank_account_cubit.dart';
import '../../features/banks/presentation/pages/bank_transfer_page.dart';
import '../../features/banks/presentation/pages/new_bank_account_page.dart';
import '../../features/bills/domain/entities/bill_account_draft.dart';
import '../../features/bills/presentation/cubits/bill_account_cubit.dart';
import '../../features/bills/presentation/cubits/bills_cubit.dart';
import '../../features/bills/presentation/pages/bill_account_page.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/cards/presentation/cubits/card_cubit.dart';
import '../../features/cards/presentation/pages/card_page.dart';
import '../../features/funding/presentation/cubits/add_card_cubit.dart';
import '../../features/funding/presentation/cubits/funding_cubit.dart';
import '../../features/funding/presentation/cubits/link_bank_cubit.dart';
import '../../features/funding/presentation/pages/add_card_page.dart';
import '../../features/funding/presentation/pages/funding_page.dart';
import '../../features/funding/presentation/pages/link_bank_page.dart';
import '../../features/notifications/presentation/cubits/notifications_cubit.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/domain/usecases/check_onboarding_complete.dart';
import '../../features/onboarding/presentation/cubits/onboarding_cubit.dart';
import '../../features/onboarding/presentation/pages/language_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/payments/domain/entities/payment_draft.dart';
import '../../features/payments/domain/entities/payment_receipt.dart';
import '../../features/payments/domain/entities/recipient.dart';
import '../../features/payments/presentation/cubits/amount_cubit.dart';
import '../../features/payments/presentation/cubits/my_qr_cubit.dart';
import '../../features/payments/presentation/cubits/review_cubit.dart';
import '../../features/payments/presentation/cubits/scan_cubit.dart';
import '../../features/payments/presentation/cubits/send_cubit.dart';
import '../../features/payments/presentation/pages/amount_page.dart';
import '../../features/payments/presentation/pages/my_qr_page.dart';
import '../../features/payments/presentation/pages/payment_result_page.dart';
import '../../features/payments/presentation/pages/review_page.dart';
import '../../features/payments/presentation/pages/scan_page.dart';
import '../../features/payments/presentation/pages/send_page.dart';
import '../../features/profile/presentation/cubits/profile_cubit.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reload/presentation/cubits/reload_cubit.dart';
import '../../features/reload/presentation/pages/reload_page.dart';
import '../../features/requests/domain/entities/requests_tab.dart';
import '../../features/requests/presentation/cubits/pay_link_cubit.dart';
import '../../features/requests/presentation/cubits/request_money_cubit.dart';
import '../../features/requests/presentation/cubits/requests_cubit.dart';
import '../../features/requests/presentation/cubits/split_cubit.dart';
import '../../features/requests/presentation/pages/pay_link_page.dart';
import '../../features/requests/presentation/pages/request_money_page.dart';
import '../../features/requests/presentation/pages/requests_page.dart';
import '../../features/requests/presentation/pages/split_page.dart';
import '../../features/rewards/presentation/cubits/rewards_cubit.dart';
import '../../features/rewards/presentation/pages/rewards_page.dart';
import '../../features/security/presentation/cubits/change_pin_cubit.dart';
import '../../features/security/presentation/cubits/security_cubit.dart';
import '../../features/security/presentation/pages/change_pin_page.dart';
import '../../features/security/presentation/pages/security_alert_page.dart';
import '../../features/security/presentation/pages/security_page.dart';
import '../../features/wallet/presentation/cubits/activity_cubit.dart';
import '../../features/wallet/presentation/cubits/home_cubit.dart';
import '../../features/wallet/presentation/cubits/insights_cubit.dart';
import '../../features/wallet/presentation/cubits/transaction_detail_cubit.dart';
import '../../features/wallet/presentation/pages/activity_page.dart';
import '../../features/wallet/presentation/pages/home_page.dart';
import '../../features/wallet/presentation/pages/insights_page.dart';
import '../../features/wallet/presentation/pages/transaction_detail_page.dart';
import '../config/app_config.dart';
import '../mock/mock_qr_codes.dart';
import '../security/app_lock.dart';
import '../security/runtime_guard.dart';
import '../security/session_store.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'not_found_page.dart';

class AppRouter {
  static const String _fromParameter = 'from';

  static const Set<String> _authRoutes = {AppRoutes.otp, AppRoutes.pin, AppRoutes.signIn};
  static const Set<String> _moneyRoutes = {
    AppRoutes.addMoney,
    AppRoutes.bankAccountNew,
    AppRoutes.bankTransfer,
    AppRoutes.billAccount,
    AppRoutes.bills,
    AppRoutes.card,
    AppRoutes.payAmount,
    AppRoutes.payLink,
    AppRoutes.payReview,
    AppRoutes.reload,
    AppRoutes.scan,
    AppRoutes.send,
    AppRoutes.split,
    AppRoutes.withdraw,
  };
  static const Set<String> _onboardingRoutes = {AppRoutes.language, AppRoutes.welcome};

  final AppLock _appLock;

  final CheckOnboardingComplete _checkOnboardingComplete;

  final GetIt _injector;

  final RuntimeGuard _runtimeGuard;

  final SessionStore _sessionStore;

  late final GoRouter config = GoRouter(
    errorBuilder: (context, state) => const NotFoundPage(),
    initialLocation: AppRoutes.home,
    redirect: _redirect,
    refreshListenable: Listenable.merge([_sessionStore, _appLock, _runtimeGuard]),
    routes: [
      GoRoute(builder: (context, state) => const LanguagePage(), path: AppRoutes.language),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<OnboardingCubit>(), child: const WelcomePage()),
        path: AppRoutes.welcome,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<PhoneCubit>(), child: const PhonePage()),
        path: AppRoutes.signIn,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<OtpCubit>(param1: state.extra),
          child: const OtpPage(),
        ),
        path: AppRoutes.otp,
        redirect: (context, state) => state.extra is OtpChallenge ? null : AppRoutes.signIn,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<PinCubit>(param1: state.extra),
          child: const PinPage(),
        ),
        path: AppRoutes.pin,
        redirect: (context, state) => state.extra is OtpVerification ? null : AppRoutes.signIn,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<UnlockCubit>(), child: const UnlockPage()),
        path: AppRoutes.unlock,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<SendCubit>()..load(), child: const SendPage()),
        path: AppRoutes.send,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<ScanCubit>(),
          child: ScanPage(demoCodes: _injector<AppConfig>().usesMockApi ? MockQrCodes.all : const []),
        ),
        path: AppRoutes.scan,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<MyQrCubit>()..load(), child: const MyQrPage()),
        path: AppRoutes.myQr,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<BillsCubit>()..load(), child: const BillsPage()),
        path: AppRoutes.bills,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<BillAccountCubit>(param1: state.extra)..load(),
          child: const BillAccountPage(),
        ),
        path: AppRoutes.billAccount,
        redirect: (context, state) => state.extra is BillAccountDraft ? null : AppRoutes.bills,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<ReloadCubit>()..load(), child: const ReloadPage()),
        path: AppRoutes.reload,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<BankPayeesCubit>()..load(), child: const BankTransferPage()),
        path: AppRoutes.bankTransfer,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<NewBankAccountCubit>()..load(), child: const NewBankAccountPage()),
        path: AppRoutes.bankAccountNew,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<RequestMoneyCubit>()..load(), child: const RequestMoneyPage()),
        path: AppRoutes.request,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<RequestsCubit>(param1: state.extra is RequestsTab ? state.extra : null)..load(),
          child: const RequestsPage(),
        ),
        path: AppRoutes.requests,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<SplitCubit>()..load(), child: const SplitPage()),
        path: AppRoutes.split,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<PayLinkCubit>(param1: state.uri.queryParameters)..load(),
          child: const PayLinkPage(),
        ),
        path: AppRoutes.payLink,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<AccountCubit>()..load(), child: const AccountPage()),
        path: AppRoutes.account,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<ProfileSetupCubit>()..load(), child: const ProfileSetupPage()),
        path: AppRoutes.accountEdit,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<KycCubit>(), child: const KycPage()),
        path: AppRoutes.kyc,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<FundingCubit>(param1: false)..load(), child: const FundingPage()),
        path: AppRoutes.addMoney,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<FundingCubit>(param1: true)..load(), child: const FundingPage()),
        path: AppRoutes.withdraw,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<LinkBankCubit>()..load(), child: const LinkBankPage()),
        path: AppRoutes.linkBank,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<AddCardCubit>(), child: const AddCardPage()),
        path: AppRoutes.addCard,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<CardCubit>()..load(),
          child: CardPage(isSandbox: _injector<AppConfig>().usesMockApi),
        ),
        path: AppRoutes.card,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<TransactionDetailCubit>(param1: state.pathParameters['id'])..load(),
          child: const TransactionDetailPage(),
        ),
        path: AppRoutes.transaction,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<InsightsCubit>()..load(), child: const InsightsPage()),
        path: AppRoutes.insights,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<NotificationsCubit>()..load(), child: const NotificationsPage()),
        path: AppRoutes.notifications,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<SecurityCubit>()..load(), child: const SecurityPage()),
        path: AppRoutes.security,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(create: (_) => _injector<ChangePinCubit>(), child: const ChangePinPage()),
        path: AppRoutes.changePin,
      ),
      GoRoute(
        builder: (context, state) => SecurityAlertPage(threats: _runtimeGuard.threats),
        path: AppRoutes.securityAlert,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<AmountCubit>(param1: state.extra)..load(),
          child: const AmountPage(),
        ),
        path: AppRoutes.payAmount,
        redirect: (context, state) => state.extra is Recipient ? null : AppRoutes.home,
      ),
      GoRoute(
        builder: (context, state) => BlocProvider(
          create: (_) => _injector<ReviewCubit>(param1: state.extra)..load(),
          child: const ReviewPage(),
        ),
        path: AppRoutes.payReview,
        redirect: (context, state) => state.extra is PaymentDraft ? null : AppRoutes.home,
      ),
      GoRoute(
        builder: (context, state) => PaymentResultPage(receipt: state.extra! as PaymentReceipt),
        path: AppRoutes.payDone,
        redirect: (context, state) => state.extra is PaymentReceipt ? null : AppRoutes.home,
      ),
      StatefulShellRoute.indexedStack(
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => BlocProvider(create: (_) => _injector<HomeCubit>()..load(), child: const HomePage()),
                path: AppRoutes.home,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => BlocProvider(create: (_) => _injector<ActivityCubit>()..load(), child: const ActivityPage()),
                path: AppRoutes.activity,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => BlocProvider(create: (_) => _injector<RewardsCubit>()..load(), child: const RewardsPage()),
                path: AppRoutes.rewards,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => BlocProvider(create: (_) => _injector<ProfileCubit>()..load(), child: const ProfilePage()),
                path: AppRoutes.profile,
              ),
            ],
          ),
        ],
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      ),
    ],
  );

  AppRouter(this._appLock, this._checkOnboardingComplete, this._injector, this._runtimeGuard, this._sessionStore);

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final isOnboardingRoute = _onboardingRoutes.contains(location);
    final isAuthRoute = _authRoutes.contains(location);
    if (!_checkOnboardingComplete()) return isOnboardingRoute ? null : AppRoutes.language;
    if (!_sessionStore.isSignedIn) return isAuthRoute ? null : AppRoutes.signIn;
    if (_appLock.isLocked) return location == AppRoutes.unlock ? null : Uri(path: AppRoutes.unlock, queryParameters: {_fromParameter: state.uri.toString()}).toString();
    if (location == AppRoutes.unlock) return _returnLocation(state.uri.queryParameters[_fromParameter]);
    if (_runtimeGuard.isCompromised && _moneyRoutes.contains(location)) return AppRoutes.securityAlert;
    return isOnboardingRoute || isAuthRoute ? AppRoutes.home : null;
  }

  String _returnLocation(String? from) => from != null && from.startsWith('/') && !from.startsWith('//') && !from.startsWith(AppRoutes.unlock) ? from : AppRoutes.home;
}
