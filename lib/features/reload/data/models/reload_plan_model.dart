import '../../../../core/utils/money.dart';
import '../../domain/entities/reload_kind.dart';
import '../../domain/entities/reload_plan.dart';

class ReloadPlanModel {
  final int amountCents;
  final int validityDays;

  final int? dataMb;
  final int? minutes;

  final String id;
  final String kind;
  final String name;

  const ReloadPlanModel({required this.amountCents, required this.validityDays, this.dataMb, this.minutes, required this.id, required this.kind, required this.name});

  factory ReloadPlanModel.fromJson(Map<String, dynamic> json) => ReloadPlanModel(
    amountCents: json['amountCents'] as int,
    validityDays: json['validityDays'] as int,
    dataMb: json['dataMb'] as int?,
    minutes: json['minutes'] as int?,
    id: json['id'] as String,
    kind: json['kind'] as String,
    name: json['name'] as String,
  );

  ReloadPlan? toEntity() {
    final kind = ReloadKind.values.asNameMap()[this.kind];
    return kind == null ? null : ReloadPlan(amount: Money(amountCents), dataMb: dataMb, id: id, kind: kind, minutes: minutes, name: name, validityDays: validityDays);
  }
}
