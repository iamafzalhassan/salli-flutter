import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/features/funding/domain/entities/bank_link_challenge.dart';
import 'package:salli/features/funding/domain/entities/card_details.dart';
import 'package:salli/features/funding/domain/entities/funding_source.dart';
import 'package:salli/features/funding/domain/repositories/funding_repository.dart';
import 'package:salli/features/funding/domain/usecases/add_card.dart';
import 'package:salli/features/funding/presentation/cubits/add_card_cubit.dart';
import 'package:salli/features/payments/domain/entities/funding_source_type.dart';

class _FakeFundingRepository implements FundingRepository {
  final List<CardDetails> added = [];

  @override
  Future<Result<FundingSource>> addCard(CardDetails details) async {
    added.add(details);
    return Ok(FundingSource(id: 'card', label: 'Visa', last4: details.number.substring(details.number.length - 4), type: FundingSourceType.card));
  }

  @override
  Future<Result<List<FundingSource>>> getSources() => throw UnimplementedError();

  @override
  Future<Result<BankLinkChallenge>> linkBank(String bankCode, String accountNumber, {String? branchCode}) => throw UnimplementedError();

  @override
  Future<Result<void>> removeSource(String sourceId) => throw UnimplementedError();

  @override
  Future<Result<FundingSource>> verifyBankLink(String challengeId, String code) => throw UnimplementedError();
}

void main() {
  late _FakeFundingRepository repository;

  AddCardCubit cubit({String number = '4111111111111111', String expiry = '1230', String cvv = '123'}) => AddCardCubit(AddCard(repository), clock: () => DateTime(2026, 9, 21))
    ..numberChanged(number)
    ..expiryChanged(expiry)
    ..cvvChanged(cvv);

  setUp(() => repository = _FakeFundingRepository());

  test('adds a valid card with a four-digit year', () async {
    final card = cubit();
    await card.save();
    expect(card.state.isAdded, isTrue);
    expect(repository.added.single.expiryYear, 2030);
  });

  test('catches a mistyped number before it reaches the server', () async {
    final card = cubit(number: '4111111111111112');
    await card.save();
    expect(card.state.failure, const Failure(FailureCodes.invalidCardNumber));
    expect(repository.added, isEmpty);
  });

  test('catches an expired card', () async {
    final card = cubit(expiry: '0826');
    await card.save();
    expect(card.state.failure, const Failure(FailureCodes.cardExpired));
  });

  test('accepts a card that expires this month', () async {
    final card = cubit(expiry: '0926');
    await card.save();
    expect(card.state.isAdded, isTrue);
  });

  test('needs a three or four digit CVV', () async {
    final card = cubit(cvv: '12');
    await card.save();
    expect(card.state.failure, const Failure(FailureCodes.invalidRequest));
  });
}
