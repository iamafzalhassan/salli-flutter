import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/security_event_model.dart';
import '../models/trusted_device_model.dart';

class SecurityRemoteDataSource {
  final ApiClient _client;

  const SecurityRemoteDataSource(this._client);

  Future<void> changePin({required String newPinHash, required String pinHash}) => _client.post(ApiPaths.pinChange, body: {'newPinHash': newPinHash, 'pinHash': pinHash});

  Future<List<TrustedDeviceModel>> getDevices() async => [for (final item in (await _client.get(ApiPaths.devices))['items'] as List<dynamic>) TrustedDeviceModel.fromJson(item as Map<String, dynamic>)];

  Future<List<SecurityEventModel>> getEvents() async => [for (final item in (await _client.get(ApiPaths.securityEvents))['items'] as List<dynamic>) SecurityEventModel.fromJson(item as Map<String, dynamic>)];
}
