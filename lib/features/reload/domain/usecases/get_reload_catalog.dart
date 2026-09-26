import '../../../../core/errors/result.dart';
import '../../../../core/utils/mobile_operator.dart';
import '../entities/reload_catalog.dart';
import '../repositories/reload_repository.dart';

class GetReloadCatalog {
  final ReloadRepository _repository;

  const GetReloadCatalog(this._repository);

  Future<Result<ReloadCatalog>> call(MobileOperator operator) => _repository.getCatalog(operator);
}
