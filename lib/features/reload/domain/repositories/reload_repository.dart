import '../../../../core/errors/result.dart';
import '../../../../core/utils/mobile_operator.dart';
import '../entities/recent_reload.dart';
import '../entities/reload_catalog.dart';

abstract interface class ReloadRepository {
  Future<Result<ReloadCatalog>> getCatalog(MobileOperator operator);

  Future<Result<List<RecentReload>>> getRecentReloads();
}
