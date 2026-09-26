import '../../../../core/utils/money.dart';
import '../../domain/entities/reload_catalog.dart';
import 'reload_plan_model.dart';

class ReloadCatalogModel {
  final List<int> amounts;

  final List<ReloadPlanModel> plans;

  const ReloadCatalogModel({required this.amounts, required this.plans});

  factory ReloadCatalogModel.fromJson(Map<String, dynamic> json) =>
      ReloadCatalogModel(amounts: [for (final amount in json['amounts'] as List<dynamic>) amount as int], plans: [for (final item in json['items'] as List<dynamic>) ReloadPlanModel.fromJson(item as Map<String, dynamic>)]);

  ReloadCatalog toEntity() => ReloadCatalog(amounts: [for (final cents in amounts) Money(cents)], plans: [for (final plan in plans) ?plan.toEntity()]);
}
