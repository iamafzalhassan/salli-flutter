import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/failure.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/lanka_qr.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/core/utils/phone_number.dart';
import 'package:salli/features/payments/presentation/cubits/my_qr_cubit.dart';
import 'package:salli/features/profile/domain/entities/profile.dart';
import 'package:salli/features/profile/domain/repositories/profile_repository.dart';
import 'package:salli/features/profile/domain/usecases/get_profile.dart';

class _FakeProfileRepository implements ProfileRepository {
  final Result<Profile> result;

  const _FakeProfileRepository(this.result);

  @override
  Future<Result<Profile>> getProfile() async => result;

  @override
  Future<Result<Profile>> updateProfile({String? displayName, DateTime? dateOfBirth}) => throw UnimplementedError();
}

void main() {
  final profile = Profile(displayName: 'Nimal Perera', id: 'user', phone: PhoneNumber.tryParse('0712223344')!);

  Future<MyQrCubit> loaded([Result<Profile>? result]) async {
    final cubit = MyQrCubit(GetProfile(_FakeProfileRepository(result ?? Ok(profile))));
    await cubit.load();
    return cubit;
  }

  test('builds a static personal code that pays this number', () async {
    final code = LankaQr.parse((await loaded()).state.payload!);
    expect(code.isPersonal, isTrue);
    expect(code.isDynamic, isFalse);
    expect(code.accountId, '+94712223344');
    expect(code.name, 'Nimal Perera');
    expect(code.amount, isNull);
  });

  test('falls back to the phone number when the profile has no name', () async {
    final code = LankaQr.parse((await loaded(Ok(Profile(id: 'user', phone: profile.phone)))).state.payload!);
    expect(code.name, profile.phone.display);
  });

  test('an amount makes the code dynamic, and removing it makes it static again', () async {
    final cubit = (await loaded())..amountChanged(const Money(50000));
    expect(LankaQr.parse(cubit.state.payload!).amount, const Money(50000));
    cubit.amountChanged(null);
    expect(LankaQr.parse(cubit.state.payload!).isDynamic, isFalse);
  });

  test('a zero amount is treated as no amount', () async => expect(((await loaded())..amountChanged(Money.zero)).state.amount, isNull));

  test('a failed profile load shows the failure and no code', () async {
    final cubit = await loaded(const Err(Failure.network()));
    expect(cubit.state.failure, const Failure.network());
    expect(cubit.state.payload, isNull);
    expect(cubit.state.isLoading, isFalse);
  });
}
