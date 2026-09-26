import '../../domain/entities/trusted_device.dart';

class TrustedDeviceModel {
  final bool hasBiometricKey;
  final bool isCurrent;

  final String id;
  final String platform;

  final DateTime boundAt;

  const TrustedDeviceModel({required this.hasBiometricKey, required this.isCurrent, required this.id, required this.platform, required this.boundAt});

  factory TrustedDeviceModel.fromJson(Map<String, dynamic> json) =>
      TrustedDeviceModel(hasBiometricKey: json['hasBiometricKey'] as bool, isCurrent: json['isCurrent'] as bool, id: json['id'] as String, platform: json['platform'] as String, boundAt: DateTime.parse(json['boundAt'] as String));

  TrustedDevice toEntity() => TrustedDevice(boundAt: boundAt, hasBiometricKey: hasBiometricKey, id: id, isCurrent: isCurrent, platform: platform);
}
