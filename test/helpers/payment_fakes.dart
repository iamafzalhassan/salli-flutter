import 'dart:typed_data';

import 'package:salli/core/errors/result.dart';
import 'package:salli/core/security/authorization.dart';
import 'package:salli/core/security/biometric_availability.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/core/utils/phone_number.dart';
import 'package:salli/features/account/domain/entities/account_limits.dart';
import 'package:salli/features/account/domain/entities/account_tier.dart';
import 'package:salli/features/account/domain/entities/kyc_submission.dart';
import 'package:salli/features/account/domain/entities/verification.dart';
import 'package:salli/features/account/domain/repositories/account_repository.dart';
import 'package:salli/features/auth/domain/entities/biometric_status.dart';
import 'package:salli/features/auth/domain/repositories/biometric_repository.dart';
import 'package:salli/features/payments/domain/entities/merchant.dart';
import 'package:salli/features/payments/domain/entities/merchant_category.dart';
import 'package:salli/features/payments/domain/entities/payee.dart';
import 'package:salli/features/payments/domain/entities/payment_draft.dart';
import 'package:salli/features/payments/domain/entities/payment_receipt.dart';
import 'package:salli/features/payments/domain/entities/recipient.dart';
import 'package:salli/features/payments/domain/entities/scanned_code.dart';
import 'package:salli/features/payments/domain/entities/step_up_reason.dart';
import 'package:salli/features/payments/domain/repositories/payments_repository.dart';
import 'package:salli/features/wallet/domain/entities/dispute.dart';
import 'package:salli/features/wallet/domain/entities/dispute_reason.dart';
import 'package:salli/features/wallet/domain/entities/monthly_insights.dart';
import 'package:salli/features/wallet/domain/entities/transaction_detail.dart';
import 'package:salli/features/wallet/domain/entities/transaction_filter.dart';
import 'package:salli/features/wallet/domain/entities/transaction_page.dart';
import 'package:salli/features/wallet/domain/entities/wallet.dart';
import 'package:salli/features/wallet/domain/repositories/wallet_repository.dart';

final Payee testPayee = Payee(name: 'Fathima Rizna', phone: PhoneNumber.tryParse('0704445566')!);

final PersonRecipient testRecipient = PersonRecipient(testPayee);

const MerchantRecipient testMerchant = MerchantRecipient(
  merchant: Merchant(category: MerchantCategory.grocery, city: 'Colombo 07', id: 'LKQR00000001', name: 'Keells Super'),
  qr: 'qr',
);

class FakeAccountRepository implements AccountRepository {
  static const AccountLimits basicLimits = AccountLimits(daily: Money.rupees(50000), dailyUsed: Money.zero, monthly: Money.rupees(200000), monthlyUsed: Money.zero, perPayment: Money.rupees(25000), tier: AccountTier.basic);

  final AccountLimits limits;

  const FakeAccountRepository({this.limits = basicLimits});

  @override
  Future<Result<AccountLimits>> getLimits() async => Ok(limits);

  @override
  Future<Result<Verification>> getVerification() => throw UnimplementedError();

  @override
  Future<Result<Verification>> submitKyc(KycSubmission submission) => throw UnimplementedError();
}

class FakeBiometricRepository implements BiometricRepository {
  final bool isEnabled;

  const FakeBiometricRepository({this.isEnabled = false});

  @override
  Future<void> disable() async {}

  @override
  Future<Result<void>> enable(String pin) async => const Ok(null);

  @override
  Future<BiometricStatus> status() async => BiometricStatus(availability: BiometricAvailability.available, isEnabled: isEnabled);
}

class FakePaymentsRepository implements PaymentsRepository {
  final List<Authorization> authorizations = [];

  final List<PaymentDraft> drafts = [];

  final List<Result<PaymentReceipt>> results = [];

  final List<Result<ScannedCode>> resolutions = [];

  final List<String> payloads = [];

  Set<StepUpReason> stepUpReasons = const {};

  @override
  Future<Result<Set<StepUpReason>>> assessRisk(PaymentDraft draft) async => Ok(stepUpReasons);

  @override
  Future<Result<List<Payee>>> getRecentPayees() async => const Ok([]);

  @override
  Future<Result<Payee>> lookupPayee(PhoneNumber phone) async => Ok(testPayee);

  @override
  Future<Result<ScannedCode>> resolveCode(String payload) async {
    payloads.add(payload);
    return resolutions.removeAt(0);
  }

  @override
  Future<Result<PaymentReceipt>> sendPayment(PaymentDraft draft, Authorization authorization) async {
    authorizations.add(authorization);
    drafts.add(draft);
    return results.removeAt(0);
  }
}

class FakeWalletRepository implements WalletRepository {
  final Money balance;

  const FakeWalletRepository({this.balance = const Money(1000000)});

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<Result<Uint8List>> exportStatement(DateTime from, DateTime to, {required String holder, required String phone}) => throw UnimplementedError();

  @override
  Future<Result<MonthlyInsights>> getInsights(DateTime month) => throw UnimplementedError();

  @override
  Future<Result<TransactionDetail>> getTransaction(String id) => throw UnimplementedError();

  @override
  Future<Result<TransactionPage>> getTransactions({String? cursor, required int limit, TransactionFilter filter = const TransactionFilter()}) async => const Ok(TransactionPage(items: []));

  @override
  Future<Result<Wallet>> getWallet() async => Ok(Wallet(balance: balance, currency: 'LKR'));

  @override
  Future<Result<Dispute>> reportProblem(String transactionId, DisputeReason reason, String? details) => throw UnimplementedError();
}
