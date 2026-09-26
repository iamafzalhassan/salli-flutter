import 'package:equatable/equatable.dart';

import '../../../../core/security/biometric_availability.dart';

class BiometricStatus extends Equatable {
  final bool isEnabled;

  final BiometricAvailability availability;

  const BiometricStatus({required this.isEnabled, required this.availability});

  bool get canUse => isEnabled && availability == BiometricAvailability.available;

  @override
  List<Object?> get props => [isEnabled, availability];
}
