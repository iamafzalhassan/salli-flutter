import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/usecases/get_insights.dart';
import 'insights_state.dart';

class InsightsCubit extends Cubit<InsightsState> {
  final DateTime Function() _clock;

  final GetInsights _getInsights;

  InsightsCubit(this._getInsights, [DateTime Function()? clock]) : _clock = clock ?? DateTime.now, super(InsightsState(month: _monthOf((clock ?? DateTime.now)())));

  Future<void> load() async {
    final month = state.month;
    emit(state.copyWith(failure: () => null, status: InsightsStatus.loading));
    final result = await _getInsights(month);
    if (isClosed || month != state.month) return;
    emit(switch (result) {
      Ok(:final value) => state.copyWith(insights: () => value, status: InsightsStatus.ready),
      Err(:final failure) => state.copyWith(failure: () => failure, insights: () => null, status: InsightsStatus.failure),
    });
  }

  Future<void> nextMonth() => _show(DateTime(state.month.year, state.month.month + 1));

  Future<void> previousMonth() => _show(DateTime(state.month.year, state.month.month - 1));

  static DateTime _monthOf(DateTime moment) => DateTime(moment.year, moment.month);

  Future<void> _show(DateTime month) async {
    final latest = _monthOf(_clock());
    if (month.isAfter(latest)) return;
    emit(InsightsState(canGoForward: month.isBefore(latest), month: month));
    await load();
  }
}
