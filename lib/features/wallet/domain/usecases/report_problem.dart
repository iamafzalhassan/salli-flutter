import '../../../../core/errors/result.dart';
import '../entities/dispute.dart';
import '../entities/dispute_reason.dart';
import '../repositories/wallet_repository.dart';

class ReportProblem {
  final WalletRepository _repository;

  const ReportProblem(this._repository);

  Future<Result<Dispute>> call(String transactionId, DisputeReason reason, String? details) => _repository.reportProblem(transactionId, reason, details);
}
