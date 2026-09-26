import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/security/authorization.dart';
import 'package:salli/core/security/biometric_prompt_text.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/auth/domain/usecases/get_biometric_status.dart';
import 'package:salli/features/cards/domain/entities/card_secrets.dart';
import 'package:salli/features/cards/domain/entities/card_status.dart';
import 'package:salli/features/cards/domain/entities/card_transaction.dart';
import 'package:salli/features/cards/domain/entities/virtual_card.dart';
import 'package:salli/features/cards/domain/repositories/cards_repository.dart';
import 'package:salli/features/cards/domain/usecases/freeze_card.dart';
import 'package:salli/features/cards/domain/usecases/get_card.dart';
import 'package:salli/features/cards/domain/usecases/get_card_transactions.dart';
import 'package:salli/features/cards/domain/usecases/make_test_purchase.dart';
import 'package:salli/features/cards/domain/usecases/reveal_card.dart';
import 'package:salli/features/cards/domain/usecases/set_card_limit.dart';
import 'package:salli/features/cards/presentation/cubits/card_cubit.dart';

import '../../../../helpers/payment_fakes.dart';

const VirtualCard _card = VirtualCard(expiryMonth: 9, expiryYear: 2030, holderName: 'AFZAL', id: 'card', last4: '4242', network: 'visa', spendLimit: Money.rupees(50000), spent: Money.zero, status: CardStatus.active);

class _FakeCardsRepository implements CardsRepository {
  final List<Result<CardSecrets>> reveals = [];

  @override
  Future<Result<VirtualCard>> getCard() async => const Ok(_card);

  @override
  Future<Result<List<CardTransaction>>> getTransactions(String cardId) async => const Ok([]);

  @override
  Future<Result<CardTransaction>> makeTestPurchase(String cardId) => throw UnimplementedError();

  @override
  Future<Result<CardSecrets>> reveal(String cardId, Authorization authorization) async => reveals.removeAt(0);

  @override
  Future<Result<VirtualCard>> setFrozen(String cardId, {required bool isFrozen}) async => Ok(
    VirtualCard(
      expiryMonth: _card.expiryMonth,
      expiryYear: _card.expiryYear,
      holderName: _card.holderName,
      id: _card.id,
      last4: _card.last4,
      network: _card.network,
      spendLimit: _card.spendLimit,
      spent: _card.spent,
      status: isFrozen ? CardStatus.frozen : CardStatus.active,
    ),
  );

  @override
  Future<Result<VirtualCard>> setSpendLimit(String cardId, Money limit) => throw UnimplementedError();
}

void main() {
  const secrets = CardSecrets(cvv: '123', expiryMonth: 9, expiryYear: 2030, number: '4000000000004242');
  const prompt = BiometricPromptText(cancel: 'Use PIN', title: 'Show card details');

  late _FakeCardsRepository repository;

  Future<CardCubit> loaded({bool isBiometricEnabled = false, Duration revealDuration = CardCubit.defaultRevealDuration}) async {
    final cubit = CardCubit(
      FreezeCard(repository),
      GetBiometricStatus(FakeBiometricRepository(isEnabled: isBiometricEnabled)),
      GetCard(repository),
      GetCardTransactions(repository),
      MakeTestPurchase(repository),
      RevealCard(repository),
      SetCardLimit(repository),
      revealDuration,
    );
    await cubit.load();
    return cubit;
  }

  setUp(() => repository = _FakeCardsRepository());

  test('reveals the details and hides them again after a while', () async {
    repository.reveals.add(const Ok(secrets));
    final cubit = await loaded(revealDuration: const Duration(milliseconds: 10));
    await cubit.reveal(const PinAuthorization('482915'));
    expect(cubit.state.secrets, secrets);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(cubit.state.secrets, isNull);
    await cubit.close();
  });

  test('a cancelled biometric prompt reports back quietly so the PIN can be asked', () async {
    repository.reveals.add(const Err(Failure(FailureCodes.biometricCancelled)));
    final cubit = await loaded(isBiometricEnabled: true);
    final failure = await cubit.reveal(const BiometricAuthorization(prompt));
    expect(CardCubit.pinFallbackCodes, contains(failure!.code));
    expect(cubit.state.failure, isNull);
    await cubit.close();
  });

  test('freezing updates the card', () async {
    final cubit = await loaded();
    await cubit.setFrozen(true);
    expect(cubit.state.card?.isFrozen, isTrue);
    await cubit.close();
  });
}
