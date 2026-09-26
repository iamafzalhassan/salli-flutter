import 'package:equatable/equatable.dart';

class TrustedDevice extends Equatable {
  final bool hasBiometricKey;
  final bool isCurrent;

  final String id;
  final String platform;

  final DateTime boundAt;

  const TrustedDevice({required this.hasBiometricKey, required this.isCurrent, required this.id, required this.platform, required this.boundAt});

  @override
  List<Object?> get props => [hasBiometricKey, isCurrent, id, platform, boundAt];
}
