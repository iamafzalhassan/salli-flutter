import '../../domain/entities/merchant.dart';
import '../../domain/entities/merchant_category.dart';

class MerchantModel {
  final String category;
  final String city;
  final String id;
  final String name;

  const MerchantModel({required this.category, required this.city, required this.id, required this.name});

  factory MerchantModel.fromJson(Map<String, dynamic> json) => MerchantModel(category: json['category'] as String, city: json['city'] as String, id: json['id'] as String, name: json['name'] as String);

  Merchant toEntity() => Merchant(category: MerchantCategory.values.asNameMap()[category] ?? MerchantCategory.other, city: city, id: id, name: name);
}
