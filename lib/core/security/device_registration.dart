import 'package:equatable/equatable.dart';

class DeviceRegistration extends Equatable {
  final String id;
  final String platform;
  final String publicKey;

  const DeviceRegistration({required this.id, required this.platform, required this.publicKey});

  @override
  List<Object?> get props => [id, platform, publicKey];
}
