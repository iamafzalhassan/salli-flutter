import '../../../../core/errors/result.dart';
import '../entities/account_limits.dart';
import '../repositories/account_repository.dart';

class GetLimits {
  final AccountRepository _repository;

  const GetLimits(this._repository);

  Future<Result<AccountLimits>> call() => _repository.getLimits();
}
