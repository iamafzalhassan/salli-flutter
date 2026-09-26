import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'saved_biller.dart';
import 'schedule_run_status.dart';

class BillSchedule extends Equatable {
  final bool autopay;

  final int dayOfMonth;

  final String id;

  final DateTime nextRunAt;

  final DateTime? lastRunAt;

  final Money? amountDue;

  final SavedBiller savedBiller;

  final ScheduleRunStatus? lastStatus;

  const BillSchedule({required this.autopay, required this.dayOfMonth, required this.id, required this.nextRunAt, this.lastRunAt, this.amountDue, required this.savedBiller, this.lastStatus});

  @override
  List<Object?> get props => [autopay, dayOfMonth, id, nextRunAt, lastRunAt, amountDue, savedBiller, lastStatus];
}
