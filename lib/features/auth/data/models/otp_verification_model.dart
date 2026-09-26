import '../../domain/entities/otp_verification.dart';

class OtpVerificationModel {
  final bool isNewUser;
  final bool requiresNic;

  final String pinSalt;
  final String registrationToken;

  const OtpVerificationModel({required this.isNewUser, required this.requiresNic, required this.pinSalt, required this.registrationToken});

  factory OtpVerificationModel.fromJson(Map<String, dynamic> json) =>
      OtpVerificationModel(isNewUser: json['isNewUser'] as bool, requiresNic: json['requiresNic'] as bool? ?? false, pinSalt: json['pinSalt'] as String, registrationToken: json['registrationToken'] as String);

  OtpVerification toEntity() => OtpVerification(isNewUser: isNewUser, pinSalt: pinSalt, registrationToken: registrationToken, requiresNic: requiresNic);
}
