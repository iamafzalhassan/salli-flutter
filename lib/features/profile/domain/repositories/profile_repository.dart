import '../../../../core/errors/result.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Result<Profile>> getProfile();

  Future<Result<Profile>> updateProfile({String? displayName, DateTime? dateOfBirth});
}
