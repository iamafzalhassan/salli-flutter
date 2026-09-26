import '../../../../core/errors/result.dart';
import '../entities/recent_reload.dart';
import '../repositories/reload_repository.dart';

class GetRecentReloads {
  final ReloadRepository _repository;

  const GetRecentReloads(this._repository);

  Future<Result<List<RecentReload>>> call() => _repository.getRecentReloads();
}
