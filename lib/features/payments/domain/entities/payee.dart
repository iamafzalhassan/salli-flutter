import 'package:equatable/equatable.dart';

import '../../../../core/utils/phone_number.dart';

class Payee extends Equatable {
  final String? name;

  final PhoneNumber phone;

  const Payee({this.name, required this.phone});

  String get displayName => name ?? phone.display;

  @override
  List<Object?> get props => [name, phone];
}
