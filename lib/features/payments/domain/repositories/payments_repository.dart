import '../../../../core/errors/result.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/utils/phone_number.dart';
import '../entities/payee.dart';
import '../entities/payment_draft.dart';
import '../entities/payment_receipt.dart';
import '../entities/scanned_code.dart';
import '../entities/step_up_reason.dart';

abstract interface class PaymentsRepository {
  Future<Result<Set<StepUpReason>>> assessRisk(PaymentDraft draft);

  Future<Result<List<Payee>>> getRecentPayees();

  Future<Result<Payee>> lookupPayee(PhoneNumber phone);

  Future<Result<ScannedCode>> resolveCode(String payload);

  Future<Result<PaymentReceipt>> sendPayment(PaymentDraft draft, Authorization authorization);
}
