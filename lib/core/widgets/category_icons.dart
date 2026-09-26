import 'package:flutter/material.dart';

abstract final class CategoryIcons {
  static const Map<String, IconData> _icons = {
    'bank': Icons.account_balance_rounded,
    'bill': Icons.receipt_long_rounded,
    'bills': Icons.receipt_long_rounded,
    'card': Icons.credit_card_rounded,
    'cashback': Icons.savings_rounded,
    'dining': Icons.restaurant_rounded,
    'electricity': Icons.bolt_rounded,
    'fee': Icons.percent_rounded,
    'fees': Icons.percent_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'grocery': Icons.shopping_basket_rounded,
    'insurance': Icons.health_and_safety_rounded,
    'leasing': Icons.directions_car_rounded,
    'online': Icons.language_rounded,
    'other': Icons.category_rounded,
    'reload': Icons.phone_android_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'telecom': Icons.cell_tower_rounded,
    'television': Icons.tv_rounded,
    'transfer': Icons.swap_horiz_rounded,
    'transfers': Icons.swap_horiz_rounded,
    'transport': Icons.local_taxi_rounded,
    'water': Icons.water_drop_rounded,
  };

  static IconData of(String category) => _icons[category] ?? Icons.storefront_rounded;
}
