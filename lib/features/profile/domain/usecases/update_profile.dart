import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository _repository;

  const UpdateProfile(this._repository);

  Future<Result<Profile>> call({String? displayName, DateTime? dateOfBirth}) => _repository.updateProfile(dateOfBirth: dateOfBirth, displayName: displayName);
}
