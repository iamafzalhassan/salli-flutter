import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';

class BiometricRemoteDataSource {
  final ApiClient _client;

  const BiometricRemoteDataSource(this._client);

  Future<void> enroll({required String pinHash, required String publicKey}) => _client.post(ApiPaths.biometricKey, body: {'pinHash': pinHash, 'publicKey': publicKey});

  Future<void> remove() => _client.delete(ApiPaths.biometricKey);
}
