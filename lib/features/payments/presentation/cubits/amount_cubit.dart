import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/amount_input.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../account/domain/entities/account_limits.dart';
import '../../../account/domain/usecases/get_limits.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../../../wallet/domain/usecases/get_wallet.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_limits.dart';
import '../../domain/entities/recipient.dart';
import 'amount_state.dart';

class AmountCubit extends Cubit<AmountState> {
  final GetLimits _getLimits;

  final GetWallet _getWallet;

  final Recipient _recipient;

  AmountCubit(this._getLimits, this._getWallet, this._recipient) : super(AmountState(input: _initialInput(_recipient)));

  Recipient get recipient => _recipient;

  void backspace() => _update(state.input.backspace());

  void clearDraft() => emit(state.copyWith(draft: () => null));

  void decimalPoint() => _update(state.input.addDecimalPoint());

  void digitEntered(int digit) => _update(state.input.append(digit));

  Future<void> load() async {
    final (wallet, limits) = await (_getWallet(), _getLimits()).wait;
    if (isClosed) return;
    emit(state.copyWith(balance: wallet is Ok<Wallet> ? () => wallet.value.balance : null, limits: limits is Ok<AccountLimits> ? () => limits.value : null));
  }

  void noteChanged(String note) => emit(state.copyWith(note: note));

  void review() {
    final amount = state.input.money;
    final balance = state.balance;
    final limits = state.limits;
    final failureCode = switch (amount) {
      _ when !amount.isPositive => FailureCodes.invalidAmount,
      _ when _recipient.isIncoming => null,
      _ when amount > (limits?.perPayment ?? PaymentLimits.perPayment) => FailureCodes.limitExceeded,
      _ when limits != null && amount + _recipient.fee > limits.dailyRemaining => FailureCodes.dailyLimitExceeded,
      _ when limits != null && amount + _recipient.fee > limits.monthlyRemaining => FailureCodes.monthlyLimitExceeded,
      _ when balance != null && amount + _recipient.fee > balance => FailureCodes.insufficientFunds,
      _ => null,
    };
    if (failureCode != null) {
      emit(state.copyWith(errorToken: state.errorToken + 1, failure: () => Failure(failureCode)));
      return;
    }
    final note = state.note.trim();
    emit(
      state.copyWith(
        draft: () => PaymentDraft(amount: amount, idempotencyKey: IdGenerator.next(), note: note.isEmpty ? null : note, recipient: _recipient),
      ),
    );
  }

  static AmountInput _initialInput(Recipient recipient) {
    final amount = recipient.suggestedAmount;
    return amount == null ? const AmountInput() : AmountInput.of(amount);
  }

  void _update(AmountInput input) {
    if (input != state.input) emit(state.copyWith(failure: () => null, input: input));
  }
}
