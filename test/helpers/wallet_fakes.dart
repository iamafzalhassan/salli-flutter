import 'dart:typed_data';

import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/core/utils/phone_number.dart';
import 'package:salli/features/notifications/domain/entities/app_notification.dart';
import 'package:salli/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:salli/features/profile/domain/entities/profile.dart';
import 'package:salli/features/profile/domain/repositories/profile_repository.dart';
import 'package:salli/features/requests/domain/entities/bill_split.dart';
import 'package:salli/features/requests/domain/entities/money_request.dart';
import 'package:salli/features/requests/domain/repositories/requests_repository.dart';
import 'package:salli/features/wallet/domain/entities/category_spend.dart';
import 'package:salli/features/wallet/domain/entities/dispute.dart';
import 'package:salli/features/wallet/domain/entities/dispute_reason.dart';
import 'package:salli/features/wallet/domain/entities/monthly_insights.dart';
import 'package:salli/features/wallet/domain/entities/timeline_status.dart';
import 'package:salli/features/wallet/domain/entities/timeline_step.dart';
import 'package:salli/features/wallet/domain/entities/transaction_detail.dart';
import 'package:salli/features/wallet/domain/entities/transaction_filter.dart';
import 'package:salli/features/wallet/domain/entities/transaction_page.dart';
import 'package:salli/features/wallet/domain/entities/transaction_status.dart';
import 'package:salli/features/wallet/domain/entities/transaction_type.dart';
import 'package:salli/features/wallet/domain/entities/wallet.dart';
import 'package:salli/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:salli/features/wallet/domain/repositories/wallet_repository.dart';

import 'payment_fakes.dart';

final WalletTransaction testTransaction = WalletTransaction(
  amount: const Money(-150000),
  counterpartyName: 'Kavindi Silva',
  createdAt: DateTime.utc(2026, 9, 21, 9),
  id: 'txn-1',
  status: TransactionStatus.completed,
  type: TransactionType.transferOut,
);

final TransactionDetail testDetail = TransactionDetail(
  counterpartyPhone: '+94771112233',
  fee: Money.zero,
  reference: 'SAL12345678',
  repeatRecipient: testRecipient,
  timeline: [
    TimelineStep(at: DateTime.utc(2026, 9, 21, 9), status: TimelineStatus.initiated),
    TimelineStep(at: DateTime.utc(2026, 9, 21, 9, 0, 2), status: TimelineStatus.completed),
  ],
  transaction: testTransaction,
);

final Dispute testDispute = Dispute(createdAt: DateTime.utc(2026, 9, 21, 10), id: 'dispute-1', reason: DisputeReason.duplicate, reference: 'DSP12345678', status: 'open');

final Profile testProfile = Profile(displayName: 'Afzal Hassan', id: 'user-1', phone: PhoneNumber.tryParse('0771234567')!);

class ScriptedWalletRepository implements WalletRepository {
  final List<(DateTime, DateTime, String, String)> statements = [];

  final List<(String, DisputeReason, String?)> reports = [];

  final List<DateTime> insightMonths = [];

  final List<TransactionFilter> filters = [];

  Result<Dispute> dispute = Ok(testDispute);

  Result<MonthlyInsights> insights = Ok(
    MonthlyInsights(
      categories: const [CategorySpend(amount: Money(428550), category: 'grocery', count: 1)],
      income: const Money(3250000),
      month: DateTime(2026, 9),
      previousSpending: Money.zero,
      spending: const Money(428550),
    ),
  );

  Result<TransactionDetail> detail = Ok(testDetail);

  Result<TransactionPage> page = Ok(TransactionPage(items: [testTransaction]));

  Result<Uint8List> statement = Ok(Uint8List.fromList(const [37, 80, 68, 70]));

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<Result<Uint8List>> exportStatement(DateTime from, DateTime to, {required String holder, required String phone}) async {
    statements.add((from, to, holder, phone));
    return statement;
  }

  @override
  Future<Result<MonthlyInsights>> getInsights(DateTime month) async {
    insightMonths.add(month);
    return insights;
  }

  @override
  Future<Result<TransactionDetail>> getTransaction(String id) async => detail;

  @override
  Future<Result<TransactionPage>> getTransactions({String? cursor, required int limit, TransactionFilter filter = const TransactionFilter()}) async {
    filters.add(filter);
    return page;
  }

  @override
  Future<Result<Wallet>> getWallet() => throw UnimplementedError();

  @override
  Future<Result<Dispute>> reportProblem(String transactionId, DisputeReason reason, String? details) async {
    reports.add((transactionId, reason, details));
    return dispute;
  }
}

class StaticProfileRepository implements ProfileRepository {
  const StaticProfileRepository();

  @override
  Future<Result<Profile>> getProfile() async => Ok(testProfile);

  @override
  Future<Result<Profile>> updateProfile({String? displayName, DateTime? dateOfBirth}) => throw UnimplementedError();
}

class EmptyRequestsRepository implements RequestsRepository {
  const EmptyRequestsRepository();

  @override
  Future<Result<MoneyRequest>> cancel(String requestId) => throw UnimplementedError();

  @override
  Future<Result<MoneyRequest>> create(PhoneNumber phone, Money amount, String? note) => throw UnimplementedError();

  @override
  Future<Result<BillSplit>> createSplit(Money total, String? note, List<PhoneNumber> phones, {required bool includeSelf}) => throw UnimplementedError();

  @override
  Future<Result<MoneyRequest>> decline(String requestId) => throw UnimplementedError();

  @override
  Future<Result<List<MoneyRequest>>> getRequests() async => const Ok([]);

  @override
  Future<Result<List<BillSplit>>> getSplits() => throw UnimplementedError();

  @override
  Future<Result<MoneyRequest>> remind(String requestId) => throw UnimplementedError();
}

class StaticNotificationsRepository implements NotificationsRepository {
  final int unreadCount;

  const StaticNotificationsRepository({this.unreadCount = 0});

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<Result<List<AppNotification>>> getNotifications() async => const Ok([]);

  @override
  Future<Result<int>> getUnreadCount() async => Ok(unreadCount);

  @override
  Future<Result<void>> markAllRead() async => const Ok(null);

  @override
  Future<Result<void>> markRead(String id) async => const Ok(null);
}
