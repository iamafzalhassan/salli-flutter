import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/otp_challenge.dart';

class PhoneState extends Equatable {
  final bool isSubmitting;

  final String input;

  final Failure? failure;

  final OtpChallenge? challenge;

  final PhoneNumber? phone;

  const PhoneState({this.isSubmitting = false, this.input = '', this.failure, this.challenge, this.phone});

  @override
  List<Object?> get props => [isSubmitting, input, failure, challenge, phone];
}
