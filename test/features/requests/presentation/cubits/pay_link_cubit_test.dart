import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/payments/domain/entities/recipient.dart';
import 'package:salli/features/payments/domain/usecases/lookup_payee.dart';
import 'package:salli/features/requests/presentation/cubits/pay_link_cubit.dart';

import '../../../../helpers/payment_fakes.dart';

void main() {
  Future<PayLinkCubit> loaded(Map<String, String> query) async {
    final cubit = PayLinkCubit(query, LookupPayee(FakePaymentsRepository()));
    await cubit.load();
    return cubit;
  }

  test('a link with an amount goes straight to review', () async {
    final cubit = await loaded(const {'amount': '50000', 'note': 'Lunch', 'to': '+94704445566'});
    expect(cubit.state.draft?.amount, const Money(50000));
    expect(cubit.state.draft?.note, 'Lunch');
    expect(cubit.state.draft?.recipient, testRecipient);
  });

  test('a link without an amount opens amount entry', () async {
    final cubit = await loaded(const {'to': '+94704445566'});
    expect(cubit.state.recipient, isA<PersonRecipient>());
    expect(cubit.state.draft, isNull);
  });

  test('a broken link says so', () async => expect((await loaded(const {'to': 'nope'})).state.isInvalid, isTrue));
}
