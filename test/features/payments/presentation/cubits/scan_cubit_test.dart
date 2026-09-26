import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/payments/domain/entities/scanned_code.dart';
import 'package:salli/features/payments/domain/usecases/resolve_code.dart';
import 'package:salli/features/payments/presentation/cubits/scan_cubit.dart';

import '../../../../helpers/payment_fakes.dart';

void main() {
  const invalid = Err<ScannedCode>(Failure(FailureCodes.invalidQr));

  late FakePaymentsRepository repository;

  ScanCubit cubit() => ScanCubit(ResolveCode(repository));

  setUp(() => repository = FakePaymentsRepository());

  test('a code without an amount opens amount entry for its recipient', () async {
    repository.resolutions.add(const Ok(ScannedCode(recipient: testMerchant)));
    final scan = cubit();
    await scan.codeDetected('keells');
    expect(scan.state.recipient, testMerchant);
    expect(scan.state.draft, isNull);
    expect(repository.payloads, ['keells']);
  });

  test('a code with a fixed amount goes straight to a draft with a fresh idempotency key', () async {
    repository.resolutions.add(const Ok(ScannedCode(amount: Money(82000), recipient: testMerchant)));
    final scan = cubit();
    await scan.codeDetected('pickme');
    final draft = scan.state.draft!;
    expect(draft.amount, const Money(82000));
    expect(draft.recipient, testMerchant);
    expect(draft.idempotencyKey, isNotEmpty);
    expect(scan.state.recipient, isNull);
  });

  test('a rejected code shows why and is not resolved again while the camera keeps seeing it', () async {
    repository.resolutions.add(invalid);
    final scan = cubit();
    await scan.codeDetected('bad');
    await scan.codeDetected('bad');
    expect(scan.state.failure, const Failure(FailureCodes.invalidQr));
    expect(scan.state.errorToken, 1);
    expect(repository.payloads, ['bad']);
  });

  test('dismissing the failure lets the camera try the same code again', () async {
    repository.resolutions
      ..add(const Err(Failure.network()))
      ..add(Ok(ScannedCode(recipient: testRecipient)));
    final scan = cubit();
    await scan.codeDetected('fathima');
    scan.dismissFailure();
    expect(scan.state.failure, isNull);
    await scan.codeDetected('fathima');
    expect(scan.state.recipient, testRecipient);
  });

  test('choosing a code from the gallery retries even a rejected one', () async {
    repository.resolutions
      ..add(invalid)
      ..add(const Ok(ScannedCode(recipient: testMerchant)));
    final scan = cubit();
    await scan.codeDetected('keells');
    await scan.codeSelected('keells');
    expect(scan.state.recipient, testMerchant);
    expect(scan.state.failure, isNull);
  });

  test('ignores new codes until the current result is cleared', () async {
    repository.resolutions
      ..add(const Ok(ScannedCode(recipient: testMerchant)))
      ..add(Ok(ScannedCode(recipient: testRecipient)));
    final scan = cubit();
    await scan.codeDetected('keells');
    await scan.codeDetected('fathima');
    expect(repository.payloads, ['keells']);
    scan.clearResult();
    await scan.codeDetected('fathima');
    expect(scan.state.recipient, testRecipient);
  });

  test('an image without a code explains that nothing was found', () {
    final scan = cubit()..imageHadNoCode();
    expect(scan.state.failure, const Failure(FailureCodes.qrNotFound));
    expect(scan.state.errorToken, 1);
  });
}
