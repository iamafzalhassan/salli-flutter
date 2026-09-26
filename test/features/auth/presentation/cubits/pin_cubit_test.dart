import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/failure_codes.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/security/authorization.dart';
import 'package:salli/core/security/session.dart';
import 'package:salli/core/utils/phone_number.dart';
import 'package:salli/features/auth/domain/entities/otp_challenge.dart';
import 'package:salli/features/auth/domain/entities/otp_verification.dart';
import 'package:salli/features/auth/domain/repositories/auth_repository.dart';
import 'package:salli/features/auth/domain/usecases/create_account.dart';
import 'package:salli/features/auth/domain/usecases/reset_pin.dart';
import 'package:salli/features/auth/domain/usecases/sign_in.dart';
import 'package:salli/features/auth/presentation/cubits/pin_cubit.dart';
import 'package:salli/features/auth/presentation/cubits/pin_state.dart';

final Session _session = Session(accessExpiresAt: DateTime.utc(2030), accessToken: 'access', refreshToken: 'refresh', userId: 'user');

class _FakeAuthRepository implements AuthRepository {
  final List<String> createdPins = [];
  final List<String> resetPins = [];
  final List<String> signedInPins = [];

  final List<String?> resetNics = [];

  Result<Session> result = Ok(_session);

  @override
  Future<Result<Session>> createAccount(OtpVerification verification, String pin) async {
    createdPins.add(pin);
    return result;
  }

  @override
  Future<Result<OtpChallenge>> requestOtp(PhoneNumber phone) => throw UnimplementedError();

  @override
  Future<Result<Session>> resetPin(OtpVerification verification, String pin, String? nic) async {
    resetNics.add(nic);
    resetPins.add(pin);
    return result;
  }

  @override
  Future<Result<Session>> signIn(OtpVerification verification, String pin) async {
    signedInPins.add(pin);
    return result;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<void>> unlock(Authorization authorization) => throw UnimplementedError();

  @override
  Future<Result<OtpVerification>> verifyOtp(OtpChallenge challenge, String code) => throw UnimplementedError();
}

void main() {
  late _FakeAuthRepository repository;

  PinCubit cubit({required bool isNewUser, bool requiresNic = false}) =>
      PinCubit(CreateAccount(repository), OtpVerification(isNewUser: isNewUser, pinSalt: 'salt', registrationToken: 'token', requiresNic: requiresNic), ResetPin(repository), SignIn(repository));

  Future<void> enter(PinCubit cubit, String pin) async {
    for (final digit in pin.split('')) {
      await cubit.digitEntered(int.parse(digit));
    }
  }

  setUp(() => repository = _FakeAuthRepository());

  test('a new user starts at create and an existing user at enter', () {
    expect(cubit(isNewUser: true).state.step, PinStep.create);
    expect(cubit(isNewUser: false).state.step, PinStep.enter);
  });

  test('a weak PIN is rejected and stays on create', () async {
    final pinCubit = cubit(isNewUser: true);
    await enter(pinCubit, '123456');
    expect(pinCubit.state.step, PinStep.create);
    expect(pinCubit.state.failure, const Failure(FailureCodes.pinWeak));
    expect(pinCubit.state.errorToken, 1);
  });

  test('a mismatched confirmation starts over', () async {
    final pinCubit = cubit(isNewUser: true);
    await enter(pinCubit, '482915');
    expect(pinCubit.state.step, PinStep.confirm);
    await enter(pinCubit, '482916');
    expect(pinCubit.state.step, PinStep.create);
    expect(pinCubit.state.failure, const Failure(FailureCodes.pinMismatch));
    expect(repository.createdPins, isEmpty);
  });

  test('a matching confirmation creates the account', () async {
    final pinCubit = cubit(isNewUser: true);
    await enter(pinCubit, '482915');
    await enter(pinCubit, '482915');
    expect(repository.createdPins, ['482915']);
    expect(pinCubit.state.isSubmitting, isTrue);
  });

  test('an existing user signs in and a wrong PIN shakes and clears', () async {
    repository.result = const Err(Failure(FailureCodes.pinInvalid));
    final pinCubit = cubit(isNewUser: false);
    await enter(pinCubit, '482915');
    expect(repository.signedInPins, ['482915']);
    expect(pinCubit.state.step, PinStep.enter);
    expect(pinCubit.state.pin, isEmpty);
    expect(pinCubit.state.failure, const Failure(FailureCodes.pinInvalid));
  });

  test('backspace removes the last digit', () async {
    final pinCubit = cubit(isNewUser: true);
    await enter(pinCubit, '48');
    pinCubit.backspace();
    expect(pinCubit.state.pin, '4');
  });

  test('forgot PIN asks for the NIC on file, then a new PIN twice, and resets', () async {
    final pin = cubit(isNewUser: false, requiresNic: true)..startReset();
    expect(pin.state.step, PinStep.nic);
    pin
      ..nicChanged('12345')
      ..submitNic();
    expect(pin.state.failure?.code, FailureCodes.invalidNic);
    pin
      ..nicChanged('199512301234')
      ..submitNic();
    expect(pin.state.step, PinStep.create);
    await enter(pin, '739164');
    await enter(pin, '739164');
    expect(repository.resetPins.single, '739164');
    expect(repository.resetNics.single, '199512301234');
    expect(repository.signedInPins, isEmpty);
  });

  test('forgot PIN skips the NIC when none is on file and is not offered to a new user', () async {
    final pin = cubit(isNewUser: false)..startReset();
    expect(pin.state.step, PinStep.create);
    expect(pin.state.isResetting, isTrue);
    expect(cubit(isNewUser: true).canReset, isFalse);
  });
}
