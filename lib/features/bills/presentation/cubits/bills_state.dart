import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/bill_schedule.dart';
import '../../domain/entities/biller.dart';
import '../../domain/entities/saved_biller.dart';

enum BillsStatus { failure, loading, ready }

class BillsState extends Equatable {
  final bool isBusy;

  final List<Biller> billers;

  final List<BillSchedule> schedules;

  final List<SavedBiller> saved;

  final BillsStatus status;

  final Failure? actionFailure;
  final Failure? failure;

  const BillsState({this.isBusy = false, this.billers = const [], this.schedules = const [], this.saved = const [], this.status = BillsStatus.loading, this.actionFailure, this.failure});

  BillSchedule? scheduleFor(SavedBiller saved) => schedules.where((schedule) => schedule.savedBiller.id == saved.id).firstOrNull;

  BillsState copyWith({bool? isBusy, List<Biller>? billers, List<BillSchedule>? schedules, List<SavedBiller>? saved, BillsStatus? status, Failure? Function()? actionFailure, Failure? Function()? failure}) => BillsState(
    isBusy: isBusy ?? this.isBusy,
    billers: billers ?? this.billers,
    schedules: schedules ?? this.schedules,
    saved: saved ?? this.saved,
    status: status ?? this.status,
    actionFailure: actionFailure == null ? this.actionFailure : actionFailure(),
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [isBusy, billers, schedules, saved, status, actionFailure, failure];
}
