import '../../../../core/errors/result.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/utils/mobile_operator.dart';
import '../../domain/entities/recent_reload.dart';
import '../../domain/entities/reload_catalog.dart';
import '../../domain/repositories/reload_repository.dart';
import '../datasources/reload_remote_data_source.dart';

class ReloadRepositoryImpl implements ReloadRepository {
  final ReloadRemoteDataSource _remote;

  const ReloadRepositoryImpl(this._remote);

  @override
  Future<Result<ReloadCatalog>> getCatalog(MobileOperator operator) => guardApi(() async => (await _remote.getCatalog(operator.name)).toEntity());

  @override
  Future<Result<List<RecentReload>>> getRecentReloads() => guardApi(() async => [for (final recent in await _remote.getRecentReloads()) ?recent.toEntity()]);
}
