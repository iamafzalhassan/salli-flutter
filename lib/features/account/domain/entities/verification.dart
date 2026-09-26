import 'package:equatable/equatable.dart';

import 'account_tier.dart';
import 'kyc_status.dart';

class Verification extends Equatable {
  final String? maskedNic;
  final String? rejectionReason;

  final AccountTier tier;

  final DateTime? reviewedAt;
  final DateTime? submittedAt;

  final KycStatus status;

  const Verification({this.maskedNic, this.rejectionReason, required this.tier, this.reviewedAt, this.submittedAt, required this.status});

  bool get canSubmit => status == KycStatus.notStarted || status == KycStatus.rejected;

  @override
  List<Object?> get props => [maskedNic, rejectionReason, tier, reviewedAt, submittedAt, status];
}
