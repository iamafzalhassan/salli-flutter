import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/security/authorization.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/bills/domain/entities/bill.dart';
import 'package:salli/features/bills/domain/entities/bill_account_draft.dart';
import 'package:salli/features/bills/domain/entities/bill_account_kind.dart';
import 'package:salli/features/bills/domain/entities/bill_schedule.dart';
import 'package:salli/features/bills/domain/entities/biller.dart';
import 'package:salli/features/bills/domain/entities/saved_biller.dart';
import 'package:salli/features/bills/domain/repositories/bills_repository.dart';
import 'package:salli/features/bills/domain/usecases/inquire_bill.dart';
import 'package:salli/features/bills/domain/usecases/save_biller.dart';
import 'package:salli/features/bills/presentation/cubits/bill_account_cubit.dart';
import 'package:salli/features/payments/domain/entities/bill_category.dart';
import 'package:salli/features/payments/domain/entities/recipient.dart';

const Biller _ceb = Biller(accountHint: '0123456789', accountKind: BillAccountKind.account, accountPattern: r'^\d{10}$', category: BillCategory.electricity, id: 'ceb', name: 'Ceylon Electricity Board');

class _FakeBillsRepository implements BillsRepository {
  final List<String> inquired = [];
  final List<String> saved = [];

  Result<Bill> inquiry = Ok(Bill(accountNumber: '0123456789', amountDue: const Money(364000), biller: _ceb, customerName: 'A. M. Perera', dueDate: DateTime.utc(2026, 10, 3)));

  @override
  Future<Result<void>> cancelSchedule(String scheduleId) => throw UnimplementedError();

  @override
  Future<Result<void>> deleteSavedBiller(String savedBillerId) => throw UnimplementedError();

  @override
  Future<Result<List<Biller>>> getBillers() => throw UnimplementedError();

  @override
  Future<Result<List<SavedBiller>>> getSavedBillers() => throw UnimplementedError();

  @override
  Future<Result<List<BillSchedule>>> getSchedules() => throw UnimplementedError();

  @override
  Future<Result<Bill>> inquire(Biller biller, String accountNumber) async {
    inquired.add(accountNumber);
    return inquiry;
  }

  @override
  Future<Result<SavedBiller>> renameSavedBiller(String savedBillerId, String nickname) => throw UnimplementedError();

  @override
  Future<Result<SavedBiller>> saveBiller(Biller biller, String accountNumber, String nickname) async {
    saved.add('$accountNumber:$nickname');
    return Ok(SavedBiller(accountNumber: accountNumber, biller: biller, id: 'saved', nickname: nickname));
  }

  @override
  Future<Result<BillSchedule>> schedule(SavedBiller savedBiller, int dayOfMonth, Authorization? autopayAuthorization) => throw UnimplementedError();
}

void main() {
  late _FakeBillsRepository repository;

  BillAccountCubit cubit(BillAccountDraft draft) => BillAccountCubit(draft, InquireBill(repository), SaveBiller(repository));

  setUp(() => repository = _FakeBillsRepository());

  test('refuses an account that does not match the biller format without asking the server', () async {
    final account = cubit(const BillAccountDraft(biller: _ceb))..accountChanged('12345');
    await account.submit();
    expect(account.state.failure, const Failure(FailureCodes.invalidAccountNumber));
    expect(repository.inquired, isEmpty);
  });

  test('looks the bill up, saves the biller and hands over a bill recipient with the amount due', () async {
    final account = cubit(const BillAccountDraft(biller: _ceb))
      ..accountChanged('0123456789')
      ..nicknameChanged('Home');
    await account.submit();
    final recipient = account.state.recipient! as BillRecipient;
    expect(recipient.amountDue, const Money(364000));
    expect(recipient.suggestedAmount, const Money(364000));
    expect(repository.saved, ['0123456789:Home']);
  });

  test('does not save when the toggle is off', () async {
    final account = cubit(const BillAccountDraft(biller: _ceb))
      ..accountChanged('0123456789')
      ..saveToggled(false);
    await account.submit();
    expect(repository.saved, isEmpty);
  });

  test('a saved biller looks its bill up straight away and is not saved again', () async {
    final account = cubit(BillAccountDraft.saved(const SavedBiller(accountNumber: '0123456789', biller: _ceb, id: 'saved', nickname: 'Home')));
    await account.load();
    expect(repository.inquired, ['0123456789']);
    expect(repository.saved, isEmpty);
    expect(account.state.recipient, isA<BillRecipient>());
  });

  test('shows why a lookup failed', () async {
    repository.inquiry = const Err(Failure(FailureCodes.billAccountNotFound));
    final account = cubit(const BillAccountDraft(biller: _ceb))..accountChanged('0123450000');
    await account.submit();
    expect(account.state.failure, const Failure(FailureCodes.billAccountNotFound));
    expect(account.state.recipient, isNull);
  });
}
