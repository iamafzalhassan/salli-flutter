import '../../domain/entities/dispute.dart';
import '../../domain/entities/dispute_reason.dart';

class DisputeModel {
  static const Map<String, DisputeReason> reasons = {
    'duplicate': DisputeReason.duplicate,
    'not_received': DisputeReason.notReceived,
    'other': DisputeReason.other,
    'unauthorized': DisputeReason.unauthorized,
    'wrong_amount': DisputeReason.wrongAmount,
  };

  final String id;
  final String reason;
  final String reference;
  final String status;

  final DateTime createdAt;

  const DisputeModel({required this.id, required this.reason, required this.reference, required this.status, required this.createdAt});

  factory DisputeModel.fromJson(Map<String, dynamic> json) =>
      DisputeModel(id: json['id'] as String, reason: json['reason'] as String, reference: json['reference'] as String, status: json['status'] as String, createdAt: DateTime.parse(json['createdAt'] as String));

  static String apiName(DisputeReason reason) => reasons.entries.firstWhere((entry) => entry.value == reason).key;

  Dispute toEntity() => Dispute(createdAt: createdAt, id: id, reason: reasons[reason] ?? DisputeReason.other, reference: reference, status: status);
}
