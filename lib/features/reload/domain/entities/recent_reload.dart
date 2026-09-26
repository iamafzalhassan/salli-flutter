import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';

class RecentReload extends Equatable {
  final Money lastAmount;

  final PhoneNumber phone;

  const RecentReload({required this.lastAmount, required this.phone});

  @override
  List<Object?> get props => [lastAmount, phone];
}
