import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/security/authorization.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/core/utils/phone_number.dart';
import 'package:salli/features/bills/domain/entities/bill.dart';
import 'package:salli/features/bills/domain/entities/bill_schedule.dart';
import 'package:salli/features/bills/domain/entities/biller.dart';
import 'package:salli/features/bills/domain/entities/saved_biller.dart';
import 'package:salli/features/bills/domain/repositories/bills_repository.dart';
import 'package:salli/features/bills/domain/usecases/get_bill_schedules.dart';
import 'package:salli/features/notifications/domain/usecases/get_unread_count.dart';
import 'package:salli/features/notifications/domain/usecases/watch_notification_changes.dart';
import 'package:salli/features/profile/domain/entities/profile.dart';
import 'package:salli/features/profile/domain/repositories/profile_repository.dart';
import 'package:salli/features/profile/domain/usecases/get_profile.dart';
import 'package:salli/features/wallet/domain/entities/dispute.dart';
import 'package:salli/features/wallet/domain/entities/dispute_reason.dart';
import 'package:salli/features/wallet/domain/entities/monthly_insights.dart';
import 'package:salli/features/wallet/domain/entities/transaction_detail.dart';
import 'package:salli/features/wallet/domain/entities/transaction_filter.dart';
import 'package:salli/features/wallet/domain/entities/transaction_page.dart';
import 'package:salli/features/wallet/domain/entities/transaction_status.dart';
import 'package:salli/features/wallet/domain/entities/transaction_type.dart';
import 'package:salli/features/wallet/domain/entities/wallet.dart';
import 'package:salli/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:salli/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:salli/features/wallet/domain/usecases/get_transactions.dart';
import 'package:salli/features/wallet/domain/usecases/get_wallet.dart';
import 'package:salli/features/wallet/domain/usecases/watch_wallet_changes.dart';
import 'package:salli/features/wallet/presentation/cubits/home_cubit.dart';
import 'package:salli/features/wallet/presentation/cubits/home_state.dart';

import '../../../../helpers/wallet_fakes.dart';

final Profile _profile = Profile(id: 'user', phone: PhoneNumber.tryParse('0771234567')!);

const Wallet _wallet = Wallet(balance: Money(2175450), currency: 'LKR');

final WalletTransaction _transaction = WalletTransaction(
  amount: const Money(-150000),
  counterpartyName: 'Kavindi Silva',
  createdAt: DateTime.utc(2026, 9, 21),
  id: 'tx',
  status: TransactionStatus.completed,
  type: TransactionType.transferOut,
);

class _FakeBillsRepository implements BillsRepository {
  const _FakeBillsRepository();

  @override
  Future<Result<void>> cancelSchedule(String scheduleId) => throw UnimplementedError();

  @override
  Future<Result<void>> deleteSavedBiller(String savedBillerId) => throw UnimplementedError();

  @override
  Future<Result<List<Biller>>> getBillers() => throw UnimplementedError();

  @override
  Future<Result<List<SavedBiller>>> getSavedBillers() => throw UnimplementedError();

  @override
  Future<Result<List<BillSchedule>>> getSchedules() async => const Ok([]);

  @override
  Future<Result<Bill>> inquire(Biller biller, String accountNumber) => throw UnimplementedError();

  @override
  Future<Result<SavedBiller>> renameSavedBiller(String savedBillerId, String nickname) => throw UnimplementedError();

  @override
  Future<Result<SavedBiller>> saveBiller(Biller biller, String accountNumber, String nickname) => throw UnimplementedError();

  @override
  Future<Result<BillSchedule>> schedule(SavedBiller savedBiller, int dayOfMonth, Authorization? autopayAuthorization) => throw UnimplementedError();
}

class _FakeProfileRepository implements ProfileRepository {
  Result<Profile> result = Ok(_profile);

  @override
  Future<Result<Profile>> getProfile() async => result;

  @override
  Future<Result<Profile>> updateProfile({String? displayName, DateTime? dateOfBirth}) => throw UnimplementedError();
}

class _FakeWalletRepository implements WalletRepository {
  final StreamController<void> changesController = StreamController<void>.broadcast();

  Result<TransactionPage> transactions = Ok(TransactionPage(items: [_transaction]));

  Result<Wallet> wallet = const Ok(_wallet);

  int? requestedLimit;

  @override
  Stream<void> get changes => changesController.stream;

  @override
  Future<Result<Uint8List>> exportStatement(DateTime from, DateTime to, {required String holder, required String phone}) => throw UnimplementedError();

  @override
  Future<Result<MonthlyInsights>> getInsights(DateTime month) => throw UnimplementedError();

  @override
  Future<Result<TransactionDetail>> getTransaction(String id) => throw UnimplementedError();

  @override
  Future<Result<TransactionPage>> getTransactions({String? cursor, required int limit, TransactionFilter filter = const TransactionFilter()}) async {
    requestedLimit = limit;
    return transactions;
  }

  @override
  Future<Result<Wallet>> getWallet() async => wallet;

  @override
  Future<Result<Dispute>> reportProblem(String transactionId, DisputeReason reason, String? details) => throw UnimplementedError();
}

void main() {
  late _FakeProfileRepository profiles;
  late _FakeWalletRepository wallets;

  HomeCubit cubit() => HomeCubit(
    const GetBillSchedules(_FakeBillsRepository()),
    GetProfile(profiles),
    GetTransactions(wallets),
    const GetUnreadCount(StaticNotificationsRepository(unreadCount: 2)),
    GetWallet(wallets),
    const WatchNotificationChanges(StaticNotificationsRepository()),
    WatchWalletChanges(wallets),
  );

  setUp(() {
    profiles = _FakeProfileRepository();
    wallets = _FakeWalletRepository();
  });

  test('loads the profile, the wallet and the recent transactions together', () async {
    final homeCubit = cubit();
    await homeCubit.load();
    expect(homeCubit.state.status, HomeStatus.ready);
    expect(homeCubit.state.profile, _profile);
    expect(homeCubit.state.wallet, _wallet);
    expect(homeCubit.state.recent, [_transaction]);
    expect(wallets.requestedLimit, HomeCubit.recentCount);
  });

  test('any failed part fails the first load', () async {
    wallets.wallet = const Err(Failure.network());
    final homeCubit = cubit();
    await homeCubit.load();
    expect(homeCubit.state.status, HomeStatus.failure);
    expect(homeCubit.state.failure, const Failure.network());
  });

  test('a failed refresh keeps the content on screen', () async {
    final homeCubit = cubit();
    await homeCubit.load();
    profiles.result = const Err(Failure.network());
    await homeCubit.load();
    expect(homeCubit.state.status, HomeStatus.ready);
    expect(homeCubit.state.wallet, _wallet);
    expect(homeCubit.state.failure, const Failure.network());
    expect(homeCubit.state.isRefreshing, isFalse);
  });

  test('hiding the balance survives a refresh', () async {
    final homeCubit = cubit();
    await homeCubit.load();
    homeCubit.toggleBalance();
    await homeCubit.load();
    expect(homeCubit.state.isBalanceHidden, isTrue);
  });
}
