import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/core/utils/phone_number.dart';
import 'package:salli/features/payments/domain/entities/payee.dart';
import 'package:salli/features/payments/domain/usecases/get_recent_payees.dart';
import 'package:salli/features/payments/domain/usecases/lookup_payee.dart';
import 'package:salli/features/requests/domain/entities/bill_split.dart';
import 'package:salli/features/requests/domain/entities/money_request.dart';
import 'package:salli/features/requests/domain/repositories/requests_repository.dart';
import 'package:salli/features/requests/domain/usecases/create_split.dart';
import 'package:salli/features/requests/presentation/cubits/split_cubit.dart';

import '../../../../helpers/payment_fakes.dart';

class _FakeRequestsRepository implements RequestsRepository {
  final List<(Money, List<PhoneNumber>, bool)> splits = [];

  @override
  Future<Result<MoneyRequest>> cancel(String requestId) => throw UnimplementedError();

  @override
  Future<Result<MoneyRequest>> create(PhoneNumber phone, Money amount, String? note) => throw UnimplementedError();

  @override
  Future<Result<BillSplit>> createSplit(Money total, String? note, List<PhoneNumber> phones, {required bool includeSelf}) async {
    splits.add((total, phones, includeSelf));
    return Ok(BillSplit(createdAt: DateTime.utc(2026, 9, 21), id: 'split', shares: const [], total: total));
  }

  @override
  Future<Result<MoneyRequest>> decline(String requestId) => throw UnimplementedError();

  @override
  Future<Result<List<MoneyRequest>>> getRequests() => throw UnimplementedError();

  @override
  Future<Result<List<BillSplit>>> getSplits() => throw UnimplementedError();

  @override
  Future<Result<MoneyRequest>> remind(String requestId) => throw UnimplementedError();
}

void main() {
  final nimal = Payee(name: 'Nimal Perera', phone: PhoneNumber.tryParse('0712223344')!);

  late _FakeRequestsRepository repository;

  SplitCubit cubit() {
    final payments = FakePaymentsRepository();
    return SplitCubit(CreateSplit(repository), GetRecentPayees(payments), LookupPayee(payments));
  }

  setUp(() => repository = _FakeRequestsRepository());

  test('previews shares that add up to the total, including you', () {
    final split = cubit()
      ..totalChanged(const Money(1000))
      ..toggle(testPayee)
      ..toggle(nimal);
    expect(split.state.shares, const [Money(334), Money(333), Money(333)]);
    expect(split.state.shares.fold<Money>(Money.zero, (sum, share) => sum + share), const Money(1000));
  });

  test('leaving yourself out splits the bill between the others', () {
    final split = cubit()
      ..totalChanged(const Money(1000))
      ..toggle(testPayee)
      ..toggle(nimal)
      ..includeSelfToggled(false);
    expect(split.state.shares, const [Money(500), Money(500)]);
  });

  test('tapping a person again takes them out', () {
    final split = cubit()
      ..toggle(testPayee)
      ..toggle(testPayee);
    expect(split.state.participants, isEmpty);
  });

  test('needs a total and at least one person before it can send', () async {
    final split = cubit()..toggle(testPayee);
    expect(split.state.canSubmit, isFalse);
    split.totalChanged(const Money(90000));
    expect(split.state.canSubmit, isTrue);
    await split.submit();
    expect(repository.splits.single.$2, [testPayee.phone]);
    expect(split.state.created, isNotNull);
  });

  test('adds a typed number after looking it up', () async {
    final split = cubit()..phoneChanged('0704445566');
    await split.addPhone();
    expect(split.state.participants, [testPayee]);
    expect(split.state.phone, isNull);
  });
}
