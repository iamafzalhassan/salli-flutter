import 'package:equatable/equatable.dart';

import '../../../../core/utils/phone_number.dart';

class OtpChallenge extends Equatable {
  final int codeLength;

  final String id;

  final DateTime expiresAt;
  final DateTime resendAvailableAt;

  final PhoneNumber phone;

  const OtpChallenge({required this.codeLength, required this.id, required this.expiresAt, required this.resendAvailableAt, required this.phone});

  @override
  List<Object?> get props => [codeLength, id, expiresAt, resendAvailableAt, phone];
}
