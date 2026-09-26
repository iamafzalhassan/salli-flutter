import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../payments/domain/entities/funding_source_type.dart';
import '../../domain/entities/funding_source.dart';
import '../../domain/usecases/get_funding_sources.dart';
import '../../domain/usecases/remove_funding_source.dart';
import 'funding_state.dart';

class FundingCubit extends Cubit<FundingState> {
  final GetFundingSources _getFundingSources;

  final RemoveFundingSource _removeFundingSource;

  FundingCubit(this._getFundingSources, this._removeFundingSource, {required bool isWithdrawal}) : super(FundingState(isWithdrawal: isWithdrawal));

  void choose(FundingSource source) => emit(state.copyWith(recipient: () => state.isWithdrawal ? source.withdrawalRecipient : source.topUpRecipient));

  void clearResult() => emit(state.copyWith(recipient: () => null));

  Future<void> load() async {
    final result = await _getFundingSources();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(
        failure: () => null,
        sources: [
          for (final source in value)
            if (!state.isWithdrawal || source.type == FundingSourceType.bank) source,
        ],
        status: FundingStatus.ready,
      ),
      Err(:final failure) => state.copyWith(failure: () => failure, status: state.sources.isEmpty ? FundingStatus.failure : FundingStatus.ready),
    });
  }

  Future<void> remove(FundingSource source) async {
    if (state.isBusy) return;
    emit(state.copyWith(failure: () => null, isBusy: true));
    final result = await _removeFundingSource(source.id);
    if (isClosed) return;
    emit(switch (result) {
      Ok() => state.copyWith(
        isBusy: false,
        sources: [
          for (final existing in state.sources)
            if (existing.id != source.id) existing,
        ],
      ),
      Err(:final failure) => state.copyWith(failure: () => failure, isBusy: false),
    });
  }
}
