import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/profile.dart';

class ProfileModel {
  final String id;
  final String phone;

  final String? dateOfBirth;
  final String? displayName;

  const ProfileModel({required this.id, required this.phone, this.dateOfBirth, this.displayName});

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(id: json['id'] as String, phone: json['phone'] as String, dateOfBirth: json['dateOfBirth'] as String?, displayName: json['displayName'] as String?);

  Profile toEntity() {
    final dateOfBirth = this.dateOfBirth;
    return Profile(dateOfBirth: dateOfBirth == null ? null : DateTime.parse(dateOfBirth), displayName: displayName, id: id, phone: PhoneNumber.parse(phone));
  }
}
