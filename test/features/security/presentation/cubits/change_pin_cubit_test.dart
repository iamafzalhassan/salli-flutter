import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/features/security/domain/entities/security_event.dart';
import 'package:salli/features/security/domain/entities/trusted_device.dart';
import 'package:salli/features/security/domain/repositories/security_repository.dart';
import 'package:salli/features/security/domain/usecases/change_pin.dart';
import 'package:salli/features/security/presentation/cubits/change_pin_cubit.dart';
import 'package:salli/features/security/presentation/cubits/change_pin_state.dart';

class _FakeSecurityRepository implements SecurityRepository {
  final List<(String, String)> changes = [];

  Result<void> result = const Ok(null);

  @override
  Future<Result<void>> changePin(String currentPin, String newPin) async {
    changes.add((currentPin, newPin));
    return result;
  }

  @override
  Future<Result<List<TrustedDevice>>> getDevices() => throw UnimplementedError();

  @override
  Future<Result<List<SecurityEvent>>> getEvents() => throw UnimplementedError();
}

void main() {
  late _FakeSecurityRepository repository;

  Future<void> enter(ChangePinCubit cubit, String pin) async {
    for (final digit in pin.split('')) {
      await cubit.digitEntered(int.parse(digit));
    }
  }

  setUp(() => repository = _FakeSecurityRepository());

  test('asks for the current PIN, then the new one twice, then changes it', () async {
    final cubit = ChangePinCubit(ChangePin(repository));
    await enter(cubit, '482915');
    expect(cubit.state.step, ChangePinStep.create);
    await enter(cubit, '739164');
    expect(cubit.state.step, ChangePinStep.confirm);
    await enter(cubit, '739164');
    expect(repository.changes.single, ('482915', '739164'));
    expect(cubit.state.isDone, isTrue);
  });

  test('a weak new PIN is refused before anything is sent', () async {
    final cubit = ChangePinCubit(ChangePin(repository));
    await enter(cubit, '482915');
    await enter(cubit, '111111');
    expect(cubit.state.failure?.code, FailureCodes.pinWeak);
    expect(cubit.state.step, ChangePinStep.create);
  });

  test('a wrong current PIN starts over from the current PIN', () async {
    repository.result = const Err(Failure(FailureCodes.pinInvalid));
    final cubit = ChangePinCubit(ChangePin(repository));
    await enter(cubit, '482915');
    await enter(cubit, '739164');
    await enter(cubit, '739164');
    expect(cubit.state.step, ChangePinStep.current);
    expect(cubit.state.failure?.code, FailureCodes.pinInvalid);
    expect(cubit.state.isDone, isFalse);
  });
}
