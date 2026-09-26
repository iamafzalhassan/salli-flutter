import 'package:equatable/equatable.dart';

class OtpVerification extends Equatable {
  final bool isNewUser;
  final bool requiresNic;

  final String pinSalt;
  final String registrationToken;

  const OtpVerification({required this.isNewUser, this.requiresNic = false, required this.pinSalt, required this.registrationToken});

  @override
  List<Object?> get props => [isNewUser, requiresNic, pinSalt, registrationToken];
}
