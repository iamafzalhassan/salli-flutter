import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../entities/payment_draft.dart';
import '../entities/payment_receipt.dart';
import '../repositories/payments_repository.dart';

class SendPayment {
  final PaymentsRepository _repository;

  const SendPayment(this._repository);

  Future<Result<PaymentReceipt>> call(PaymentDraft draft, Authorization authorization) => _repository.sendPayment(draft, authorization);
}
