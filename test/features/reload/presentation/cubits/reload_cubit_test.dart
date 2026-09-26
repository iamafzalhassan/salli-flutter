import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/errors/result.dart';
import 'package:salli/core/utils/mobile_operator.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/core/utils/phone_number.dart';
import 'package:salli/features/payments/domain/entities/recipient.dart';
import 'package:salli/features/profile/domain/entities/profile.dart';
import 'package:salli/features/profile/domain/repositories/profile_repository.dart';
import 'package:salli/features/profile/domain/usecases/get_profile.dart';
import 'package:salli/features/reload/domain/entities/recent_reload.dart';
import 'package:salli/features/reload/domain/entities/reload_catalog.dart';
import 'package:salli/features/reload/domain/entities/reload_kind.dart';
import 'package:salli/features/reload/domain/entities/reload_plan.dart';
import 'package:salli/features/reload/domain/repositories/reload_repository.dart';
import 'package:salli/features/reload/domain/usecases/get_recent_reloads.dart';
import 'package:salli/features/reload/domain/usecases/get_reload_catalog.dart';
import 'package:salli/features/reload/presentation/cubits/reload_cubit.dart';

const ReloadPlan _plan = ReloadPlan(amount: Money(29800), dataMb: 2048, id: 'dialog-data-2', kind: ReloadKind.data, name: 'Anytime 2GB', validityDays: 30);

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<Result<Profile>> getProfile() async => Ok(Profile(id: 'user', phone: PhoneNumber.tryParse('0771234567')!));

  @override
  Future<Result<Profile>> updateProfile({String? displayName, DateTime? dateOfBirth}) => throw UnimplementedError();
}

class _FakeReloadRepository implements ReloadRepository {
  final List<MobileOperator> requested = [];

  @override
  Future<Result<ReloadCatalog>> getCatalog(MobileOperator operator) async {
    requested.add(operator);
    return const Ok(ReloadCatalog(amounts: [Money(10000)], plans: [_plan]));
  }

  @override
  Future<Result<List<RecentReload>>> getRecentReloads() async => const Ok([]);
}

void main() {
  late _FakeReloadRepository repository;

  Future<ReloadCubit> loaded() async {
    final cubit = ReloadCubit(GetProfile(_FakeProfileRepository()), GetRecentReloads(repository), GetReloadCatalog(repository));
    await cubit.load();
    return cubit;
  }

  setUp(() => repository = _FakeReloadRepository());

  test('starts with your own number and its network plans', () async {
    final cubit = await loaded();
    expect(cubit.state.phone, PhoneNumber.tryParse('0771234567'));
    expect(cubit.state.catalog?.plans, [_plan]);
    expect(repository.requested, [MobileOperator.dialog]);
  });

  test('loads each network once and follows the typed number', () async {
    final cubit = await loaded();
    await cubit.phoneChanged('0711234567');
    await cubit.phoneChanged('0771234567');
    expect(repository.requested, [MobileOperator.dialog, MobileOperator.mobitel]);
    expect(cubit.state.phone?.carrier, MobileOperator.dialog);
  });

  test('an amount chip goes straight to review with a fresh idempotency key', () async {
    final cubit = (await loaded())..amountChosen(const Money(10000));
    expect(cubit.state.draft?.amount, const Money(10000));
    expect(cubit.state.draft?.recipient, isA<ReloadRecipient>());
    expect(cubit.state.draft?.idempotencyKey, isNotEmpty);
  });

  test('a plan carries its id and price', () async {
    final cubit = (await loaded())..planChosen(_plan);
    final recipient = cubit.state.draft!.recipient as ReloadRecipient;
    expect(recipient.planId, _plan.id);
    expect(cubit.state.draft!.amount, _plan.amount);
  });

  test('another amount opens amount entry', () async {
    final cubit = (await loaded())..otherAmount();
    expect(cubit.state.recipient, isA<ReloadRecipient>());
    expect(cubit.state.draft, isNull);
  });

  test('an incomplete number clears the plans', () async {
    final cubit = await loaded();
    await cubit.phoneChanged('077');
    expect(cubit.state.phone, isNull);
    expect(cubit.state.catalog, isNull);
  });
}
