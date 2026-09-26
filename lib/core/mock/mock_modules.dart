import 'mock_approval_verifier.dart';
import 'mock_authenticator.dart';
import 'mock_checkout.dart';
import 'mock_kyc_reviewer.dart';
import 'mock_ledger.dart';
import 'mock_module.dart';
import 'mock_notifier.dart';
import 'mock_pin_verifier.dart';
import 'mock_rewards.dart';
import 'mock_risk.dart';
import 'mock_security_log.dart';
import 'mock_sms_inbox.dart';
import 'mock_store.dart';
import 'mock_wallet_seeder.dart';
import 'modules/auth_mock_module.dart';
import 'modules/banks_mock_module.dart';
import 'modules/bills_mock_module.dart';
import 'modules/cards_mock_module.dart';
import 'modules/devices_mock_module.dart';
import 'modules/funding_mock_module.dart';
import 'modules/kyc_mock_module.dart';
import 'modules/merchants_mock_module.dart';
import 'modules/notifications_mock_module.dart';
import 'modules/payments_mock_module.dart';
import 'modules/profile_mock_module.dart';
import 'modules/reload_mock_module.dart';
import 'modules/requests_mock_module.dart';
import 'modules/rewards_mock_module.dart';
import 'modules/security_mock_module.dart';
import 'modules/wallet_mock_module.dart';

List<MockModule> mockModules(MockSmsInbox inbox, MockStore store, {DateTime Function()? clock}) {
  final authenticator = MockAuthenticator(store, clock: clock);
  final ledger = MockLedger(store);
  final pinVerifier = MockPinVerifier(store, clock: clock);
  final approvalVerifier = MockApprovalVerifier(pinVerifier, store);
  final seeder = MockWalletSeeder(ledger, store, clock: clock);
  final notifier = MockNotifier(store, clock: clock);
  final rewards = MockRewards(ledger, notifier, store, clock: clock);
  final risk = MockRisk(ledger, store, clock: clock);
  final securityLog = MockSecurityLog(store, clock: clock);
  final reviewer = MockKycReviewer(notifier, store, clock: clock);
  final checkout = MockCheckout(approvalVerifier, reviewer, ledger, notifier, rewards, risk, seeder, clock: clock);
  return [
    AuthMockModule(approvalVerifier, authenticator, pinVerifier, securityLog, inbox, store, clock: clock),
    BanksMockModule(authenticator, checkout, store, clock: clock),
    BillsMockModule(approvalVerifier, authenticator, checkout, ledger, store, clock: clock),
    CardsMockModule(approvalVerifier, authenticator, checkout, ledger, securityLog, store, seeder, clock: clock),
    DevicesMockModule(authenticator, pinVerifier, securityLog, store),
    FundingMockModule(approvalVerifier, authenticator, checkout, ledger, inbox, store, seeder, clock: clock),
    KycMockModule(authenticator, reviewer, ledger, store, clock: clock),
    MerchantsMockModule(authenticator, checkout),
    NotificationsMockModule(authenticator, notifier, store),
    PaymentsMockModule(authenticator, checkout, ledger, risk, store, seeder),
    ProfileMockModule(authenticator, reviewer, store, clock: clock),
    ReloadMockModule(authenticator, checkout, ledger, seeder),
    RequestsMockModule(authenticator, ledger, notifier, store, clock: clock),
    RewardsMockModule(authenticator, notifier, rewards, store, clock: clock),
    SecurityMockModule(authenticator, store),
    WalletMockModule(authenticator, ledger, store, seeder, clock: clock),
  ];
}
