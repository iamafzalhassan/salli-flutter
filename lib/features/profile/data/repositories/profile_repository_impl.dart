import '../../../../core/errors/result.dart';
import '../../../../core/network/api_guard.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;

  const ProfileRepositoryImpl(this._remote);

  @override
  Future<Result<Profile>> getProfile() => guardApi(() async => (await _remote.getProfile()).toEntity());

  @override
  Future<Result<Profile>> updateProfile({String? displayName, DateTime? dateOfBirth}) => guardApi(() async => (await _remote.updateProfile(dateOfBirth: dateOfBirth, displayName: displayName)).toEntity());
}
