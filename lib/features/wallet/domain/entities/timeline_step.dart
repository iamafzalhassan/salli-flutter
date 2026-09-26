import 'package:equatable/equatable.dart';

import 'timeline_status.dart';

class TimelineStep extends Equatable {
  final DateTime at;

  final TimelineStatus status;

  const TimelineStep({required this.at, required this.status});

  @override
  List<Object?> get props => [at, status];
}
