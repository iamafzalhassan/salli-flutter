import '../../../../core/utils/money.dart';
import '../../domain/entities/bill_schedule.dart';
import '../../domain/entities/schedule_run_status.dart';
import 'saved_biller_model.dart';

class BillScheduleModel {
  static const Map<String, ScheduleRunStatus> _statuses = {'failed': ScheduleRunStatus.failed, 'nothing_due': ScheduleRunStatus.nothingDue, 'paid': ScheduleRunStatus.paid};

  final bool autopay;

  final int dayOfMonth;

  final int? amountDueCents;

  final String id;

  final String? lastStatus;

  final DateTime nextRunAt;

  final DateTime? lastRunAt;

  final SavedBillerModel savedBiller;

  const BillScheduleModel({required this.autopay, required this.dayOfMonth, this.amountDueCents, required this.id, this.lastStatus, required this.nextRunAt, this.lastRunAt, required this.savedBiller});

  factory BillScheduleModel.fromJson(Map<String, dynamic> json) {
    final lastRunAt = json['lastRunAt'] as String?;
    return BillScheduleModel(
      autopay: json['autopay'] as bool,
      dayOfMonth: json['dayOfMonth'] as int,
      amountDueCents: json['amountDueCents'] as int?,
      id: json['id'] as String,
      lastStatus: json['lastStatus'] as String?,
      nextRunAt: DateTime.parse(json['nextRunAt'] as String),
      lastRunAt: lastRunAt == null ? null : DateTime.parse(lastRunAt),
      savedBiller: SavedBillerModel.fromJson(json['savedBiller'] as Map<String, dynamic>),
    );
  }

  BillSchedule toEntity() {
    final amountDueCents = this.amountDueCents;
    return BillSchedule(
      amountDue: amountDueCents == null ? null : Money(amountDueCents),
      autopay: autopay,
      dayOfMonth: dayOfMonth,
      id: id,
      lastRunAt: lastRunAt,
      lastStatus: _statuses[lastStatus],
      nextRunAt: nextRunAt,
      savedBiller: savedBiller.toEntity(),
    );
  }
}
