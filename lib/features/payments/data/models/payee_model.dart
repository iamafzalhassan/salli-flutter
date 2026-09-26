import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/payee.dart';

class PayeeModel {
  final String phone;

  final String? name;

  const PayeeModel({required this.phone, this.name});

  factory PayeeModel.fromJson(Map<String, dynamic> json) => PayeeModel(phone: json['phone'] as String, name: json['name'] as String?);

  Payee toEntity() => Payee(name: name, phone: PhoneNumber.parse(phone));
}
