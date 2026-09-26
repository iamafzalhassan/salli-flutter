import 'package:equatable/equatable.dart';

import 'dispute_reason.dart';

class Dispute extends Equatable {
  final String id;
  final String reference;
  final String status;

  final DateTime createdAt;

  final DisputeReason reason;

  const Dispute({required this.id, required this.reference, required this.status, required this.createdAt, required this.reason});

  @override
  List<Object?> get props => [id, reference, status, createdAt, reason];
}
