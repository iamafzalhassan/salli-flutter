import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

class Wallet extends Equatable {
  final String currency;

  final Money balance;

  const Wallet({required this.currency, required this.balance});

  @override
  List<Object?> get props => [currency, balance];
}
