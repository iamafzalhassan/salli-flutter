import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../../domain/entities/bill_schedule.dart';
import '../../domain/entities/saved_biller.dart';
import '../../domain/usecases/cancel_bill_schedule.dart';
import '../../domain/usecases/delete_saved_biller.dart';
import '../../domain/usecases/get_bill_schedules.dart';
import '../../domain/usecases/get_billers.dart';
import '../../domain/usecases/get_saved_billers.dart';
import '../../domain/usecases/rename_saved_biller.dart';
import '../../domain/usecases/schedule_bill.dart';
import 'bills_state.dart';

class BillsCubit extends Cubit<BillsState> {
  final CancelBillSchedule _cancelBillSchedule;

  final DeleteSavedBiller _deleteSavedBiller;

  final GetBillers _getBillers;

  final GetBillSchedules _getBillSchedules;

  final GetSavedBillers _getSavedBillers;

  final RenameSavedBiller _renameSavedBiller;

  final ScheduleBill _scheduleBill;

  BillsCubit(this._cancelBillSchedule, this._deleteSavedBiller, this._getBillers, this._getBillSchedules, this._getSavedBillers, this._renameSavedBiller, this._scheduleBill) : super(const BillsState());

  Future<void> cancelSchedule(BillSchedule schedule) => _mutate(() => _cancelBillSchedule(schedule.id));

  Future<void> delete(SavedBiller saved) => _mutate(() => _deleteSavedBiller(saved.id));

  Future<void> load() async {
    if (state.billers.isEmpty) emit(state.copyWith(failure: () => null, status: BillsStatus.loading));
    final (billers, saved, schedules) = await (_getBillers(), _getSavedBillers(), _getBillSchedules()).wait;
    if (isClosed) return;
    switch ((billers, saved, schedules)) {
      case (Ok(value: final billers), Ok(value: final saved), Ok(value: final schedules)):
        emit(state.copyWith(billers: billers, failure: () => null, saved: saved, schedules: schedules, status: BillsStatus.ready));
      case _:
        final failure = [billers, saved, schedules].whereType<Err<Object?>>().first.failure;
        emit(state.copyWith(failure: () => failure, status: state.billers.isEmpty ? BillsStatus.failure : BillsStatus.ready));
    }
  }

  Future<void> rename(SavedBiller saved, String nickname) => _mutate(() => _renameSavedBiller(saved.id, nickname));

  Future<void> schedule(SavedBiller saved, int dayOfMonth, {String? pin}) => _mutate(() => _scheduleBill(saved, dayOfMonth, autopayAuthorization: pin == null ? null : PinAuthorization(pin)));

  Future<void> _mutate(Future<Result<Object?>> Function() action) async {
    if (state.isBusy) return;
    emit(state.copyWith(actionFailure: () => null, isBusy: true));
    final result = await action();
    if (isClosed) return;
    final Failure? failure = result is Err<Object?> ? result.failure : null;
    emit(state.copyWith(actionFailure: () => failure, isBusy: false));
    await load();
  }
}
