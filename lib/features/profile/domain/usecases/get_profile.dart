import '../../../../core/errors/result.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository _repository;

  const GetProfile(this._repository);

  Future<Result<Profile>> call() => _repository.getProfile();
}
