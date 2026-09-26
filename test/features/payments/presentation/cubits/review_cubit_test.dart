import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/security/authorization.dart';
import 'package:salli/core/security/biometric_prompt_text.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/auth/domain/usecases/get_biometric_status.dart';
import 'package:salli/features/payments/domain/entities/payment_draft.dart';
import 'package:salli/features/payments/domain/entities/payment_receipt.dart';
import 'package:salli/features/payments/domain/entities/step_up_reason.dart';
import 'package:salli/features/payments/domain/usecases/assess_payment_risk.dart';
import 'package:salli/features/payments/domain/usecases/send_payment.dart';
import 'package:salli/features/payments/presentation/cubits/review_cubit.dart';

import '../../../../helpers/payment_fakes.dart';

void main() {
  const prompt = BiometricPromptText(cancel: 'Use PIN', title: 'Approve payment');

  final draft = PaymentDraft(amount: const Money(50000), idempotencyKey: 'key', recipient: testRecipient);
  final receipt = PaymentReceipt(amount: const Money(50000), createdAt: DateTime.utc(2026, 9, 21), fee: Money.zero, id: 'tx', recipient: testRecipient, reference: 'SAL0000000001');

  late FakePaymentsRepository repository;

  Future<ReviewCubit> cubitWith({bool isBiometricEnabled = false}) async {
    final cubit = ReviewCubit(AssessPaymentRisk(repository), GetBiometricStatus(FakeBiometricRepository(isEnabled: isBiometricEnabled)), draft, SendPayment(repository));
    await cubit.load();
    return cubit;
  }

  Future<void> enterPin(ReviewCubit cubit) async {
    for (final digit in '482915'.split('')) {
      await cubit.digitEntered(int.parse(digit));
    }
  }

  setUp(() => repository = FakePaymentsRepository());

  test('ignores digits until the payment is being authorized', () async {
    final cubit = await cubitWith();
    await cubit.digitEntered(4);
    expect(cubit.state.pin, isEmpty);
  });

  test('without biometrics, paying opens the PIN pad and a correct PIN produces the receipt', () async {
    repository.results.add(Ok(receipt));
    final cubit = await cubitWith();
    await cubit.authorize(prompt);
    expect(cubit.state.isAuthorizing, isTrue);
    await enterPin(cubit);
    expect(cubit.state.receipt, receipt);
    expect(repository.authorizations.single, isA<PinAuthorization>());
  });

  test('with biometrics, paying approves with the biometric key straight away', () async {
    repository.results.add(Ok(receipt));
    final cubit = await cubitWith(isBiometricEnabled: true);
    await cubit.authorize(prompt);
    expect(cubit.state.receipt, receipt);
    expect(repository.authorizations.single, isA<BiometricAuthorization>());
  });

  test('cancelling the biometric prompt falls back to the PIN pad without an error', () async {
    repository.results.add(const Err(Failure(FailureCodes.biometricCancelled)));
    final cubit = await cubitWith(isBiometricEnabled: true);
    await cubit.authorize(prompt);
    expect(cubit.state.isAuthorizing, isTrue);
    expect(cubit.state.failure, isNull);
  });

  test('changed biometrics fall back to the PIN and stop offering biometrics', () async {
    repository.results.add(const Err(Failure(FailureCodes.biometricInvalidated)));
    final cubit = await cubitWith(isBiometricEnabled: true);
    await cubit.authorize(prompt);
    expect(cubit.state.isAuthorizing, isTrue);
    expect(cubit.state.canUseBiometrics, isFalse);
    expect(cubit.state.failure, const Failure(FailureCodes.biometricInvalidated));
  });

  test('a wrong PIN shakes, clears and stays on the PIN step', () async {
    repository.results.add(const Err(Failure(FailureCodes.pinInvalid)));
    final cubit = await cubitWith();
    await cubit.authorize(prompt);
    await enterPin(cubit);
    expect(cubit.state.isAuthorizing, isTrue);
    expect(cubit.state.pin, isEmpty);
    expect(cubit.state.errorToken, 1);
  });

  test('any other failure leaves the PIN step and shows the reason', () async {
    repository.results.add(const Err(Failure(FailureCodes.insufficientFunds)));
    final cubit = await cubitWith();
    await cubit.authorize(prompt);
    await enterPin(cubit);
    expect(cubit.state.isAuthorizing, isFalse);
    expect(cubit.state.failure, const Failure(FailureCodes.insufficientFunds));
  });

  test('a retry reuses the same idempotency key', () async {
    repository.results
      ..add(const Err(Failure.network()))
      ..add(Ok(receipt));
    final cubit = await cubitWith();
    await cubit.authorize(prompt);
    await enterPin(cubit);
    await cubit.authorize(prompt);
    await enterPin(cubit);
    expect(cubit.state.receipt, receipt);
    expect({for (final sent in repository.drafts) sent.idempotencyKey}, {'key'});
  });

  test('a risky payment turns off biometrics and waits before it can be approved', () async {
    repository.stepUpReasons = {StepUpReason.newPayee};
    final cubit = await cubitWith(isBiometricEnabled: true);
    expect(cubit.state.stepUpReasons, {StepUpReason.newPayee});
    expect(cubit.state.canUseBiometrics, isFalse);
    expect(cubit.state.coolingOffSeconds, ReviewCubit.coolingOffSeconds);
    await cubit.authorize(prompt);
    expect(cubit.state.isAuthorizing, isFalse);
    await cubit.close();
  });
}
