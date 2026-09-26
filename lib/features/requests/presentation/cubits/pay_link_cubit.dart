import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/payment_link.dart';
import '../../../payments/domain/entities/payment_draft.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../../payments/domain/usecases/lookup_payee.dart';
import 'pay_link_state.dart';

class PayLinkCubit extends Cubit<PayLinkState> {
  final Map<String, String> _query;

  final LookupPayee _lookupPayee;

  PayLinkCubit(this._query, this._lookupPayee) : super(const PayLinkState());

  Future<void> load() async {
    final link = PaymentLink.parse(_query);
    if (link == null) {
      emit(const PayLinkState(isInvalid: true));
      return;
    }
    emit(const PayLinkState());
    final result = await _lookupPayee(link.phone);
    if (isClosed) return;
    final amount = link.amount;
    emit(switch (result) {
      Ok(:final value) when amount != null => PayLinkState(
        draft: PaymentDraft(amount: amount, idempotencyKey: IdGenerator.next(), note: link.note, recipient: PersonRecipient(value)),
      ),
      Ok(:final value) => PayLinkState(recipient: PersonRecipient(value)),
      Err(:final failure) => PayLinkState(failure: failure),
    });
  }
}
