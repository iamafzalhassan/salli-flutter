import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/features/wallet/domain/entities/dispute_reason.dart';
import 'package:salli/features/wallet/domain/usecases/get_transaction.dart';
import 'package:salli/features/wallet/domain/usecases/report_problem.dart';
import 'package:salli/features/wallet/presentation/cubits/transaction_detail_cubit.dart';
import 'package:salli/features/wallet/presentation/cubits/transaction_detail_state.dart';

import '../../../../helpers/wallet_fakes.dart';

void main() {
  late ScriptedWalletRepository wallet;

  TransactionDetailCubit cubit() => TransactionDetailCubit(testTransaction.id, GetTransaction(wallet), ReportProblem(wallet));

  setUp(() => wallet = ScriptedWalletRepository());

  test('loads the transaction detail', () async {
    final detail = cubit();
    await detail.load();
    expect(detail.state.status, TransactionDetailStatus.ready);
    expect(detail.state.detail, testDetail);
  });

  test('shows a failure when the transaction cannot be loaded', () async {
    wallet.detail = const Err(Failure(FailureCodes.notFound));
    final detail = cubit();
    await detail.load();
    expect(detail.state.status, TransactionDetailStatus.failure);
    expect(detail.state.failure?.code, FailureCodes.notFound);
  });

  test('reporting a problem attaches the open case to the transaction', () async {
    final detail = cubit();
    await detail.load();
    await detail.report(DisputeReason.duplicate, 'Charged twice at 9am');
    expect(wallet.reports.single, (testTransaction.id, DisputeReason.duplicate, 'Charged twice at 9am'));
    expect(detail.state.detail?.dispute, testDispute);
    expect(detail.state.isReporting, isFalse);
  });

  test('a rejected report keeps the detail and shows why', () async {
    wallet.dispute = const Err(Failure(FailureCodes.disputeExists));
    final detail = cubit();
    await detail.load();
    await detail.report(DisputeReason.other, null);
    expect(detail.state.detail, testDetail);
    expect(detail.state.failure?.code, FailureCodes.disputeExists);
  });

  test('does not report twice once a case is open', () async {
    final detail = cubit();
    await detail.load();
    await detail.report(DisputeReason.duplicate, null);
    await detail.report(DisputeReason.other, null);
    expect(wallet.reports, hasLength(1));
  });
}
