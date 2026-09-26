import '../../../../core/errors/result.dart';
import '../entities/payment_draft.dart';
import '../entities/step_up_reason.dart';
import '../repositories/payments_repository.dart';

class AssessPaymentRisk {
  final PaymentsRepository _repository;

  const AssessPaymentRisk(this._repository);

  Future<Result<Set<StepUpReason>>> call(PaymentDraft draft) => _repository.assessRisk(draft);
}
