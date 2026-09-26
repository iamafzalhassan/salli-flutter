import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/requests/domain/usecases/get_requests.dart';
import 'package:salli/features/wallet/domain/entities/transaction_filter.dart';
import 'package:salli/features/wallet/domain/entities/transaction_type.dart';
import 'package:salli/features/wallet/domain/usecases/export_statement.dart';
import 'package:salli/features/wallet/domain/usecases/get_transactions.dart';
import 'package:salli/features/wallet/domain/usecases/watch_wallet_changes.dart';
import 'package:salli/features/wallet/presentation/cubits/activity_cubit.dart';
import 'package:salli/features/wallet/presentation/cubits/activity_state.dart';

import '../../../../helpers/wallet_fakes.dart';

void main() {
  late ScriptedWalletRepository wallet;

  ActivityCubit cubit() => ActivityCubit(ExportStatement(const StaticProfileRepository(), wallet), const GetRequests(EmptyRequestsRepository()), GetTransactions(wallet), WatchWalletChanges(wallet));

  setUp(() => wallet = ScriptedWalletRepository());

  test('loads the first page with no filter', () async {
    final activity = cubit();
    await activity.load();
    expect(activity.state.status, ActivityStatus.ready);
    expect(activity.state.items, [testTransaction]);
    expect(wallet.filters, [const TransactionFilter()]);
    await activity.close();
  });

  test('applying a filter reloads with it and keeps the search text', () async {
    final activity = cubit();
    const filter = TransactionFilter(max: Money.rupees(10000), query: 'kav', types: {TransactionType.transferOut});
    await activity.applyFilter(filter);
    expect(activity.state.filter, filter);
    expect(activity.state.status, ActivityStatus.ready);
    expect(wallet.filters.last, filter);
    await activity.close();
  });

  test('applying the same filter again does not reload', () async {
    final activity = cubit();
    await activity.load();
    await activity.applyFilter(const TransactionFilter());
    expect(wallet.filters, hasLength(1));
    await activity.close();
  });

  test('search waits for typing to pause and sends only the last text', () async {
    final activity = cubit();
    activity
      ..search('k')
      ..search('ka')
      ..search('kav');
    await Future<void>.delayed(ActivityCubit.searchDelay * 2);
    expect(wallet.filters, [const TransactionFilter(query: 'kav')]);
    await activity.close();
  });

  test('exports a statement for the month in the holder name', () async {
    final activity = cubit();
    final from = DateTime(2026, 8);
    final to = DateTime(2026, 9);
    final result = await activity.exportStatement(from, to);
    expect(result, isA<Ok<Object>>());
    expect(wallet.statements.single, (from, to, testProfile.displayName, testProfile.phone.display));
    expect(activity.state.isExporting, isFalse);
    await activity.close();
  });
}
