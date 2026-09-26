import 'package:equatable/equatable.dart';

import 'merchant_category.dart';

class Merchant extends Equatable {
  final String city;
  final String id;
  final String name;

  final MerchantCategory category;

  const Merchant({required this.city, required this.id, required this.name, required this.category});

  @override
  List<Object?> get props => [city, id, name, category];
}
