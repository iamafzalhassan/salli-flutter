import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/scanned_code.dart';
import '../../domain/usecases/resolve_code.dart';
import 'scan_state.dart';

class ScanCubit extends Cubit<ScanState> {
  final ResolveCode _resolveCode;

  ScanCubit(this._resolveCode) : super(const ScanState());

  void clearResult() => emit(state.copyWith(draft: () => null, recipient: () => null));

  Future<void> codeDetected(String payload) async {
    if (payload != state.rejected) await _resolve(payload);
  }

  Future<void> codeSelected(String payload) => _resolve(payload);

  void dismissFailure() => emit(state.copyWith(failure: () => null, rejected: () => null));

  void imageHadNoCode() => emit(state.copyWith(errorToken: state.errorToken + 1, failure: () => const Failure(FailureCodes.qrNotFound)));

  Future<void> _resolve(String payload) async {
    if (state.isResolving || state.hasResult) return;
    emit(state.copyWith(failure: () => null, isResolving: true));
    final result = await _resolveCode(payload);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => _resolved(value),
      Err(:final failure) => state.copyWith(errorToken: state.errorToken + 1, failure: () => failure, isResolving: false, rejected: () => payload),
    });
  }

  ScanState _resolved(ScannedCode code) {
    final amount = code.amount;
    if (amount == null) return state.copyWith(isResolving: false, recipient: () => code.recipient, rejected: () => null);
    return state.copyWith(
      draft: () => PaymentDraft(amount: amount, idempotencyKey: IdGenerator.next(), recipient: code.recipient),
      isResolving: false,
      rejected: () => null,
    );
  }
}
