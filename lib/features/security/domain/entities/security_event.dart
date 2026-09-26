import 'package:equatable/equatable.dart';

import 'security_event_kind.dart';

class SecurityEvent extends Equatable {
  final String id;

  final String? platform;

  final DateTime createdAt;

  final SecurityEventKind kind;

  const SecurityEvent({required this.id, this.platform, required this.createdAt, required this.kind});

  @override
  List<Object?> get props => [id, platform, createdAt, kind];
}
