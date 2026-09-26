import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/account/domain/entities/account_limits.dart';
import 'package:salli/features/account/domain/entities/account_tier.dart';
import 'package:salli/features/account/domain/usecases/get_limits.dart';
import 'package:salli/features/payments/presentation/cubits/amount_cubit.dart';
import 'package:salli/features/wallet/domain/usecases/get_wallet.dart';

import '../../../../helpers/payment_fakes.dart';

void main() {
  Future<AmountCubit> cubitWith(String keys) async {
    final cubit = AmountCubit(const GetLimits(FakeAccountRepository()), const GetWallet(FakeWalletRepository()), testRecipient);
    await cubit.load();
    for (final key in keys.split('')) {
      if (key == '.') {
        cubit.decimalPoint();
      } else {
        cubit.digitEntered(int.parse(key));
      }
    }
    return cubit;
  }

  test('loads the balance to show what is available', () async => expect((await cubitWith('')).state.balance, const Money(1000000)));

  test('rejects zero', () async {
    final cubit = (await cubitWith('0'))..review();
    expect(cubit.state.failure, const Failure(FailureCodes.invalidAmount));
    expect(cubit.state.draft, isNull);
    expect(cubit.state.errorToken, 1);
  });

  test('rejects more than the balance', () async {
    final cubit = (await cubitWith('10000.01'))..review();
    expect(cubit.state.failure, const Failure(FailureCodes.insufficientFunds));
  });

  test('checks the single payment limit before the balance', () async {
    final cubit = (await cubitWith('${FakeAccountRepository.basicLimits.perPayment.rupeePart + 1}'))..review();
    expect(cubit.state.failure, const Failure(FailureCodes.limitExceeded));
  });

  test('checks what is left of the daily limit', () async {
    const limits = AccountLimits(daily: Money.rupees(50000), dailyUsed: Money.rupees(45000), monthly: Money.rupees(200000), monthlyUsed: Money.zero, perPayment: Money.rupees(25000), tier: AccountTier.basic);
    final cubit = AmountCubit(const GetLimits(FakeAccountRepository(limits: limits)), const GetWallet(FakeWalletRepository()), testRecipient);
    await cubit.load();
    for (final digit in [6, 0, 0, 0]) {
      cubit.digitEntered(digit);
    }
    cubit.review();
    expect(cubit.state.failure, const Failure(FailureCodes.dailyLimitExceeded));
  });

  test('builds a draft with a fresh idempotency key and a trimmed note', () async {
    final cubit = (await cubitWith('1250.5'))
      ..noteChanged('  Lunch  ')
      ..review();
    final draft = cubit.state.draft!;
    expect(draft.amount, const Money(125050));
    expect(draft.note, 'Lunch');
    expect(draft.idempotencyKey, isNotEmpty);
    expect(draft.recipient, testRecipient);
  });

  test('typing after an error clears it', () async {
    final cubit = (await cubitWith('0'))..review();
    cubit.digitEntered(5);
    expect(cubit.state.failure, isNull);
  });
}
