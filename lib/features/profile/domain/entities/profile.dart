import 'package:equatable/equatable.dart';

import '../../../../core/utils/phone_number.dart';

class Profile extends Equatable {
  final String id;

  final String? displayName;

  final DateTime? dateOfBirth;

  final PhoneNumber phone;

  const Profile({required this.id, this.displayName, this.dateOfBirth, required this.phone});

  @override
  List<Object?> get props => [id, displayName, dateOfBirth, phone];
}
