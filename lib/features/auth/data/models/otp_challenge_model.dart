import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/otp_challenge.dart';

class OtpChallengeModel {
  final int codeLength;

  final String challengeId;

  final DateTime expiresAt;
  final DateTime resendAvailableAt;

  const OtpChallengeModel({required this.codeLength, required this.challengeId, required this.expiresAt, required this.resendAvailableAt});

  factory OtpChallengeModel.fromJson(Map<String, dynamic> json) =>
      OtpChallengeModel(codeLength: json['codeLength'] as int, challengeId: json['challengeId'] as String, expiresAt: DateTime.parse(json['expiresAt'] as String), resendAvailableAt: DateTime.parse(json['resendAvailableAt'] as String));

  OtpChallenge toEntity(PhoneNumber phone) => OtpChallenge(codeLength: codeLength, expiresAt: expiresAt, id: challengeId, phone: phone, resendAvailableAt: resendAvailableAt);
}
