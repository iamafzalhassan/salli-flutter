import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  final ApiClient _client;

  const ProfileRemoteDataSource(this._client);

  Future<ProfileModel> getProfile() async => ProfileModel.fromJson(await _client.get(ApiPaths.me));

  Future<ProfileModel> updateProfile({String? displayName, DateTime? dateOfBirth}) async => ProfileModel.fromJson(await _client.patch(ApiPaths.me, body: {'displayName': ?displayName, 'dateOfBirth': ?dateOfBirth?.toIso8601String()}));
}
