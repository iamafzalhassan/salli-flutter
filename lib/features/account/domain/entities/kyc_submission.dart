import 'package:equatable/equatable.dart';

import '../../../../core/utils/gender.dart';
import '../../../../core/utils/nic.dart';

class KycSubmission extends Equatable {
  final String fullName;
  final String nicBackDigest;
  final String nicFrontDigest;
  final String selfieDigest;

  final List<String> livenessChallenges;

  final DateTime dateOfBirth;

  final Gender gender;

  final Nic nic;

  const KycSubmission({required this.fullName, required this.nicBackDigest, required this.nicFrontDigest, required this.selfieDigest, required this.livenessChallenges, required this.dateOfBirth, required this.gender, required this.nic});

  @override
  List<Object?> get props => [fullName, nicBackDigest, nicFrontDigest, selfieDigest, livenessChallenges, dateOfBirth, gender, nic];
}
