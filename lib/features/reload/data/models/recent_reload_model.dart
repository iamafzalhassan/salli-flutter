import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/recent_reload.dart';

class RecentReloadModel {
  final int lastAmountCents;

  final String phone;

  const RecentReloadModel({required this.lastAmountCents, required this.phone});

  factory RecentReloadModel.fromJson(Map<String, dynamic> json) => RecentReloadModel(lastAmountCents: json['lastAmountCents'] as int, phone: json['phone'] as String);

  RecentReload? toEntity() {
    final phone = PhoneNumber.tryParse(this.phone);
    return phone == null ? null : RecentReload(lastAmount: Money(lastAmountCents), phone: phone);
  }
}
