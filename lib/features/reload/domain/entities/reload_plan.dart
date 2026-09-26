import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'reload_kind.dart';

class ReloadPlan extends Equatable {
  final int validityDays;

  final int? dataMb;
  final int? minutes;

  final String id;
  final String name;

  final Money amount;

  final ReloadKind kind;

  const ReloadPlan({required this.validityDays, this.dataMb, this.minutes, required this.id, required this.name, required this.amount, required this.kind});

  @override
  List<Object?> get props => [validityDays, dataMb, minutes, id, name, amount, kind];
}
