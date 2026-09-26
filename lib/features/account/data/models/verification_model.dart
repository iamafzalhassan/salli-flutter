import '../../domain/entities/account_tier.dart';
import '../../domain/entities/kyc_status.dart';
import '../../domain/entities/verification.dart';

class VerificationModel {
  static const Map<String, KycStatus> _statuses = {'not_started': KycStatus.notStarted, 'pending': KycStatus.pending, 'rejected': KycStatus.rejected, 'verified': KycStatus.verified};

  final String status;
  final String tier;

  final String? maskedNic;
  final String? rejectionReason;
  final String? reviewedAt;
  final String? submittedAt;

  const VerificationModel({required this.status, required this.tier, this.maskedNic, this.rejectionReason, this.reviewedAt, this.submittedAt});

  factory VerificationModel.fromJson(Map<String, dynamic> json) => VerificationModel(
    status: json['status'] as String,
    tier: json['tier'] as String,
    maskedNic: json['maskedNic'] as String?,
    rejectionReason: json['rejectionReason'] as String?,
    reviewedAt: json['reviewedAt'] as String?,
    submittedAt: json['submittedAt'] as String?,
  );

  Verification toEntity() {
    final reviewedAt = this.reviewedAt;
    final submittedAt = this.submittedAt;
    return Verification(
      maskedNic: maskedNic,
      rejectionReason: rejectionReason,
      reviewedAt: reviewedAt == null ? null : DateTime.parse(reviewedAt),
      status: _statuses[status] ?? KycStatus.notStarted,
      submittedAt: submittedAt == null ? null : DateTime.parse(submittedAt),
      tier: AccountTier.values.asNameMap()[tier] ?? AccountTier.basic,
    );
  }
}
