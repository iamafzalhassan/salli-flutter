import '../../../../core/errors/result.dart';
import '../entities/monthly_insights.dart';
import '../repositories/wallet_repository.dart';

class GetInsights {
  final WalletRepository _repository;

  const GetInsights(this._repository);

  Future<Result<MonthlyInsights>> call(DateTime month) => _repository.getInsights(month);
}
