import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/features/security/domain/entities/security_event.dart';
import 'package:salli/features/security/domain/entities/security_event_kind.dart';
import 'package:salli/features/security/domain/entities/trusted_device.dart';
import 'package:salli/features/security/domain/repositories/security_repository.dart';
import 'package:salli/features/security/domain/usecases/get_security_events.dart';
import 'package:salli/features/security/domain/usecases/get_trusted_devices.dart';
import 'package:salli/features/security/presentation/cubits/security_cubit.dart';
import 'package:salli/features/security/presentation/cubits/security_state.dart';

class _FakeSecurityRepository implements SecurityRepository {
  bool fails = false;

  @override
  Future<Result<void>> changePin(String currentPin, String newPin) => throw UnimplementedError();

  @override
  Future<Result<List<TrustedDevice>>> getDevices() async => fails ? const Err(Failure(FailureCodes.network)) : Ok([TrustedDevice(boundAt: DateTime.utc(2026, 9), hasBiometricKey: true, id: 'device-1', isCurrent: true, platform: 'android')]);

  @override
  Future<Result<List<SecurityEvent>>> getEvents() async => Ok([SecurityEvent(createdAt: DateTime.utc(2026, 9, 21), id: 'event-1', kind: SecurityEventKind.signedIn)]);
}

void main() {
  late _FakeSecurityRepository repository;

  SecurityCubit cubit() => SecurityCubit(GetSecurityEvents(repository), GetTrustedDevices(repository));

  setUp(() => repository = _FakeSecurityRepository());

  test('loads devices and events together', () async {
    final security = cubit();
    await security.load();
    expect(security.state.status, SecurityStatus.ready);
    expect(security.state.devices.single.id, 'device-1');
    expect(security.state.events.single.kind, SecurityEventKind.signedIn);
  });

  test('a failed first load shows the failure', () async {
    repository.fails = true;
    final security = cubit();
    await security.load();
    expect(security.state.status, SecurityStatus.failure);
    expect(security.state.failure?.code, FailureCodes.network);
  });

  test('a failed refresh keeps what was already shown', () async {
    final security = cubit();
    await security.load();
    repository.fails = true;
    await security.load();
    expect(security.state.status, SecurityStatus.ready);
    expect(security.state.devices.single.id, 'device-1');
    expect(security.state.failure?.code, FailureCodes.network);
  });
}
