import '../../../../core/security/device_registration.dart';

class AuthRequestModel {
  final String pinHash;
  final String registrationToken;

  final String? nic;

  final DeviceRegistration device;

  const AuthRequestModel({required this.pinHash, required this.registrationToken, this.nic, required this.device});

  Map<String, dynamic> toJson() => {
    'pinHash': pinHash,
    'registrationToken': registrationToken,
    'nic': ?nic,
    'device': {'id': device.id, 'platform': device.platform, 'publicKey': device.publicKey},
  };
}
