import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/security_event.dart';
import '../../domain/entities/trusted_device.dart';

enum SecurityStatus { failure, loading, ready }

class SecurityState extends Equatable {
  final List<SecurityEvent> events;

  final List<TrustedDevice> devices;

  final Failure? failure;

  final SecurityStatus status;

  const SecurityState({this.events = const [], this.devices = const [], this.failure, this.status = SecurityStatus.loading});

  @override
  List<Object?> get props => [events, devices, failure, status];
}
