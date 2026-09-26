import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/features/wallet/domain/usecases/get_insights.dart';
import 'package:salli/features/wallet/presentation/cubits/insights_cubit.dart';
import 'package:salli/features/wallet/presentation/cubits/insights_state.dart';

import '../../../../helpers/wallet_fakes.dart';

void main() {
  late ScriptedWalletRepository wallet;

  InsightsCubit cubit() => InsightsCubit(GetInsights(wallet), () => DateTime(2026, 9, 21, 10));

  setUp(() => wallet = ScriptedWalletRepository());

  test('starts on the current month and cannot go past it', () async {
    final insights = cubit();
    await insights.load();
    expect(insights.state.month, DateTime(2026, 9));
    expect(insights.state.canGoForward, isFalse);
    expect(insights.state.status, InsightsStatus.ready);
    await insights.nextMonth();
    expect(wallet.insightMonths, [DateTime(2026, 9)]);
  });

  test('steps back a month and forward again', () async {
    final insights = cubit();
    await insights.load();
    await insights.previousMonth();
    expect(insights.state.month, DateTime(2026, 8));
    expect(insights.state.canGoForward, isTrue);
    await insights.nextMonth();
    expect(insights.state.month, DateTime(2026, 9));
    expect(insights.state.canGoForward, isFalse);
    expect(wallet.insightMonths, [DateTime(2026, 9), DateTime(2026, 8), DateTime(2026, 9)]);
  });

  test('crosses the year boundary', () async {
    final insights = InsightsCubit(GetInsights(wallet), () => DateTime(2026, 1, 5));
    await insights.previousMonth();
    expect(insights.state.month, DateTime(2025, 12));
  });

  test('shows a failure when insights cannot be loaded', () async {
    wallet.insights = const Err(Failure(FailureCodes.network));
    final insights = cubit();
    await insights.load();
    expect(insights.state.status, InsightsStatus.failure);
    expect(insights.state.insights, isNull);
  });
}
