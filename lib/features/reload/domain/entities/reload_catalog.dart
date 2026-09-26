import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'reload_kind.dart';
import 'reload_plan.dart';

class ReloadCatalog extends Equatable {
  final List<Money> amounts;

  final List<ReloadPlan> plans;

  const ReloadCatalog({required this.amounts, required this.plans});

  List<ReloadPlan> plansOf(ReloadKind kind) => [
    for (final plan in plans)
      if (plan.kind == kind) plan,
  ];

  @override
  List<Object?> get props => [amounts, plans];
}
