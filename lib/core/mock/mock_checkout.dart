import '../errors/failure_codes.dart';
import '../security/approver.dart';
import 'mock_approval_verifier.dart';
import 'mock_kyc_reviewer.dart';
import 'mock_ledger.dart';
import 'mock_limits.dart';
import 'mock_notifier.dart';
import 'mock_principal.dart';
import 'mock_response.dart';
import 'mock_rewards.dart';
import 'mock_risk.dart';
import 'mock_wallet_seeder.dart';

class MockCheckout {
  static const String feeAccount = 'fees:salli';
  static const String feeName = 'Salli';
  static const String feeType = 'fee';

  final DateTime Function() _clock;

  final MockApprovalVerifier _approvalVerifier;

  final MockKycReviewer _reviewer;

  final MockLedger _ledger;

  final MockNotifier _notifier;

  final MockRewards _rewards;

  final MockRisk _risk;

  final MockWalletSeeder _seeder;

  MockCheckout(this._approvalVerifier, this._reviewer, this._ledger, this._notifier, this._rewards, this._risk, this._seeder, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<({MockResponse? rejection, Map<String, dynamic>? transaction})> charge(
    MockPrincipal principal, {
    required int amountCents,
    int feeCents = 0,
    required String creditAccount,
    required String creditName,
    String? creditPhone,
    String? note,
    required String type,
    Map<String, dynamic> meta = const {},
    Object? approval,
    List<int> approvalPayload = const [],
    bool isPreApproved = false,
  }) async {
    final payer = (await _reviewer.settle(principal.userId))!;
    final limits = MockLimits.of(payer);
    if (amountCents > limits.perPaymentCents) return (rejection: MockResponse.error(422, FailureCodes.limitExceeded, field: 'amountCents'), transaction: null);
    await _seeder.ensureSeeded(principal.userId);
    final account = MockWalletSeeder.walletAccount(principal.userId);
    final now = _clock().toUtc();
    final total = amountCents + feeCents;
    if (_ledger.outgoingSince(account, now.subtract(MockLimits.dailyWindow)) + total > limits.dailyCents) return (rejection: MockResponse.error(422, FailureCodes.dailyLimitExceeded, field: 'amountCents'), transaction: null);
    if (_ledger.outgoingSince(account, now.subtract(MockLimits.monthlyWindow)) + total > limits.monthlyCents) return (rejection: MockResponse.error(422, FailureCodes.monthlyLimitExceeded, field: 'amountCents'), transaction: null);
    if (_ledger.balanceOf(account) < total) return (rejection: MockResponse.error(422, FailureCodes.insufficientFunds, field: 'amountCents'), transaction: null);
    final rejection = isPreApproved ? null : await _approvalVerifier.verify(principal, approval, approvalPayload);
    if (rejection != null) return (rejection: rejection, transaction: null);
    final isBiometric = approval is Map<String, dynamic> && approval['method'] == Approver.biometricMethod;
    if (!isPreApproved && isBiometric && _risk.assess(principal, amountCents: amountCents, creditAccount: creditAccount, type: type).isNotEmpty) {
      return (rejection: MockResponse.error(403, FailureCodes.stepUpRequired), transaction: null);
    }
    final payerName = payer['displayName'] as String? ?? payer['phone'] as String;
    final payerPhone = payer['phone'] as String;
    final reference = _ledger.nextReference();
    final transaction = await _ledger.post(
      amountCents: amountCents,
      at: now,
      creditAccount: creditAccount,
      creditName: creditName,
      creditPhone: creditPhone,
      debitAccount: account,
      debitName: payerName,
      debitPhone: payerPhone,
      feeCents: feeCents,
      meta: meta,
      note: note,
      reference: reference,
      type: type,
    );
    if (feeCents > 0) {
      await _ledger.post(amountCents: feeCents, at: now, creditAccount: feeAccount, creditName: feeName, debitAccount: account, debitName: payerName, debitPhone: payerPhone, reference: reference, type: feeType);
    }
    if (creditAccount.startsWith(MockWalletSeeder.walletPrefix)) {
      await _notifier.notify(creditAccount.substring(MockWalletSeeder.walletPrefix.length), MockNotifier.moneyReceived, params: {'amountCents': amountCents, 'name': payerName, 'transactionId': transaction['id']});
    }
    await _rewards.afterCharge(principal.userId, transaction);
    return (rejection: null, transaction: transaction);
  }
}
