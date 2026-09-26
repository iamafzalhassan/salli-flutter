import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/banks/domain/entities/bank.dart';
import 'package:salli/features/banks/domain/entities/bank_account.dart';
import 'package:salli/features/banks/domain/entities/bank_branch.dart';
import 'package:salli/features/banks/domain/entities/bank_payee.dart';
import 'package:salli/features/banks/domain/repositories/banks_repository.dart';
import 'package:salli/features/banks/domain/usecases/get_bank_branches.dart';
import 'package:salli/features/banks/domain/usecases/get_banks.dart';
import 'package:salli/features/banks/domain/usecases/lookup_bank_account.dart';
import 'package:salli/features/banks/domain/usecases/save_bank_payee.dart';
import 'package:salli/features/banks/presentation/cubits/new_bank_account_cubit.dart';
import 'package:salli/features/payments/domain/entities/recipient.dart';

const Bank _boc = Bank(accountPattern: r'^\d{8,10}$', branchRequired: false, code: '7010', fee: Money(2500), name: 'Bank of Ceylon', shortName: 'BOC');
const Bank _peoples = Bank(accountPattern: r'^\d{15}$', branchRequired: true, code: '7135', fee: Money(2500), name: "People's Bank", shortName: "People's");
const BankBranch _kandy = BankBranch(code: '024', name: 'Kandy');

class _FakeBanksRepository implements BanksRepository {
  final List<String> saved = [];

  @override
  Future<Result<void>> deletePayee(String payeeId) => throw UnimplementedError();

  @override
  Future<Result<List<Bank>>> getBanks() async => const Ok([_boc, _peoples]);

  @override
  Future<Result<List<BankBranch>>> getBranches(Bank bank) async => const Ok([_kandy]);

  @override
  Future<Result<List<BankPayee>>> getPayees() => throw UnimplementedError();

  @override
  Future<Result<BankAccount>> lookupAccount(Bank bank, String accountNumber, {String? branchCode}) async => Ok(BankAccount(accountName: 'K. M. Silva', accountNumber: accountNumber, bank: bank, branchCode: branchCode));

  @override
  Future<Result<BankPayee>> savePayee(BankAccount account, String nickname) async {
    saved.add(nickname);
    return Ok(BankPayee(account: account, id: 'payee', nickname: nickname));
  }
}

void main() {
  late _FakeBanksRepository repository;

  Future<NewBankAccountCubit> loaded() async {
    final cubit = NewBankAccountCubit(GetBankBranches(repository), GetBanks(repository), LookupBankAccount(repository), SaveBankPayee(repository));
    await cubit.load();
    return cubit;
  }

  setUp(() => repository = _FakeBanksRepository());

  test('cannot check an account until the bank and a valid number are chosen', () async {
    final cubit = await loaded();
    expect(cubit.state.canLookup, isFalse);
    await cubit.bankSelected(_boc);
    cubit.accountChanged('12');
    expect(cubit.state.canLookup, isFalse);
    cubit.accountChanged('0012345678');
    expect(cubit.state.canLookup, isTrue);
  });

  test('a bank that needs a branch waits for one', () async {
    final cubit = await loaded();
    await cubit.bankSelected(_peoples);
    cubit.accountChanged('123456789012345');
    expect(cubit.state.branches, [_kandy]);
    expect(cubit.state.canLookup, isFalse);
    cubit.branchSelected(_kandy);
    expect(cubit.state.canLookup, isTrue);
  });

  test('shows the holder name, saves the account and hands over a recipient with the fee', () async {
    final cubit = await loaded();
    await cubit.bankSelected(_boc);
    cubit
      ..accountChanged('0012345678')
      ..nicknameChanged('Amma');
    await cubit.lookup();
    expect(cubit.state.account?.accountName, 'K. M. Silva');
    await cubit.proceed();
    final recipient = cubit.state.recipient! as BankRecipient;
    expect(recipient.fee, const Money(2500));
    expect(repository.saved, ['Amma']);
  });

  test('changing the number clears an earlier name enquiry', () async {
    final cubit = await loaded();
    await cubit.bankSelected(_boc);
    cubit.accountChanged('0012345678');
    await cubit.lookup();
    cubit.accountChanged('0012345679');
    expect(cubit.state.account, isNull);
  });
}
