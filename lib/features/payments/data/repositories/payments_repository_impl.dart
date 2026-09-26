import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/events/app_event.dart';
import '../../../../core/events/app_events.dart';
import '../../../../core/network/api_guard.dart';
import '../../../../core/security/approval_payload.dart';
import '../../../../core/security/approver.dart';
import '../../../../core/security/authorization.dart';
import '../../../../core/utils/lanka_qr.dart';
import '../../../../core/utils/phone_number.dart';
import '../../domain/entities/payee.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_receipt.dart';
import '../../domain/entities/recipient.dart';
import '../../domain/entities/scanned_code.dart';
import '../../domain/entities/step_up_reason.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_remote_data_source.dart';
import '../models/bank_transfer_request_model.dart';
import '../models/bill_payment_request_model.dart';
import '../models/funding_request_model.dart';
import '../models/merchant_payment_request_model.dart';
import '../models/reload_request_model.dart';
import '../models/risk_request_model.dart';
import '../models/transfer_request_model.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final AppEvents _events;

  final Approver _approver;

  final PaymentsRemoteDataSource _remote;

  const PaymentsRepositoryImpl(this._events, this._approver, this._remote);

  Future<PaymentReceipt> _sendTransfer(PaymentDraft draft, Payee payee, Authorization authorization) async {
    final recipientPhone = payee.phone.e164;
    final payload = ApprovalPayload.transfer(amountCents: draft.amount.cents, idempotencyKey: draft.idempotencyKey, recipientPhone: recipientPhone);
    final request = TransferRequestModel(amountCents: draft.amount.cents, approval: await _approver.approve(authorization, payload), note: draft.note, recipientPhone: recipientPhone, requestId: draft.requestId);
    return (await _remote.sendTransfer(request, idempotencyKey: draft.idempotencyKey)).toEntity();
  }

  Future<PaymentReceipt> _payMerchant(PaymentDraft draft, MerchantRecipient recipient, Authorization authorization) async {
    final payload = ApprovalPayload.merchantPayment(amountCents: draft.amount.cents, idempotencyKey: draft.idempotencyKey, merchantId: recipient.merchant.id);
    final request = MerchantPaymentRequestModel(amountCents: draft.amount.cents, approval: await _approver.approve(authorization, payload), note: draft.note, qr: recipient.qr);
    return (await _remote.payMerchant(request, idempotencyKey: draft.idempotencyKey)).toEntity(recipient.qr);
  }

  Future<PaymentReceipt> _payBill(PaymentDraft draft, BillRecipient recipient, Authorization authorization) async {
    final payload = ApprovalPayload.billPayment(accountNumber: recipient.accountNumber, amountCents: draft.amount.cents, billerId: recipient.billerId, idempotencyKey: draft.idempotencyKey);
    final request = BillPaymentRequestModel(accountNumber: recipient.accountNumber, amountCents: draft.amount.cents, approval: await _approver.approve(authorization, payload), billerId: recipient.billerId, note: draft.note);
    return (await _remote.payBill(request, idempotencyKey: draft.idempotencyKey)).toEntity(recipient);
  }

  Future<PaymentReceipt> _reload(PaymentDraft draft, ReloadRecipient recipient, Authorization authorization) async {
    final phone = recipient.phone.e164;
    final payload = ApprovalPayload.reload(amountCents: draft.amount.cents, idempotencyKey: draft.idempotencyKey, phone: phone, planId: recipient.planId);
    final request = ReloadRequestModel(amountCents: draft.amount.cents, approval: await _approver.approve(authorization, payload), note: draft.note, phone: phone, planId: recipient.planId);
    return (await _remote.reload(request, idempotencyKey: draft.idempotencyKey)).toEntity(recipient);
  }

  Future<PaymentReceipt> _sendToBank(PaymentDraft draft, BankRecipient recipient, Authorization authorization) async {
    final payload = ApprovalPayload.bankTransfer(accountNumber: recipient.accountNumber, amountCents: draft.amount.cents, bankCode: recipient.bankCode, idempotencyKey: draft.idempotencyKey);
    final request = BankTransferRequestModel(
      accountNumber: recipient.accountNumber,
      amountCents: draft.amount.cents,
      approval: await _approver.approve(authorization, payload),
      bankCode: recipient.bankCode,
      branchCode: recipient.branchCode,
      note: draft.note,
    );
    return (await _remote.bankTransfer(request, idempotencyKey: draft.idempotencyKey)).toEntity(recipient);
  }

  Future<PaymentReceipt> _topUp(PaymentDraft draft, TopUpRecipient recipient, Authorization authorization) async {
    final payload = ApprovalPayload.topUp(amountCents: draft.amount.cents, idempotencyKey: draft.idempotencyKey, sourceId: recipient.sourceId);
    final request = FundingRequestModel(amountCents: draft.amount.cents, approval: await _approver.approve(authorization, payload), sourceId: recipient.sourceId);
    return (await _remote.topUp(request, idempotencyKey: draft.idempotencyKey)).toEntity(recipient);
  }

  Future<PaymentReceipt> _withdraw(PaymentDraft draft, WithdrawalRecipient recipient, Authorization authorization) async {
    final payload = ApprovalPayload.withdrawal(amountCents: draft.amount.cents, idempotencyKey: draft.idempotencyKey, sourceId: recipient.sourceId);
    final request = FundingRequestModel(amountCents: draft.amount.cents, approval: await _approver.approve(authorization, payload), sourceId: recipient.sourceId);
    return (await _remote.withdraw(request, idempotencyKey: draft.idempotencyKey)).toEntity(recipient);
  }

  @override
  Future<Result<Set<StepUpReason>>> assessRisk(PaymentDraft draft) async {
    if (draft.recipient.isIncoming) return const Ok({});
    return guardApi(() async => RiskRequestModel.reasonsFrom(await _remote.assessRisk(RiskRequestModel(draft).toJson())));
  }

  @override
  Future<Result<List<Payee>>> getRecentPayees() => guardApi(() async => [for (final payee in await _remote.getRecentPayees()) payee.toEntity()]);

  @override
  Future<Result<Payee>> lookupPayee(PhoneNumber phone) => guardApi(() async => (await _remote.lookupPayee(phone.e164)).toEntity());

  @override
  Future<Result<ScannedCode>> resolveCode(String payload) async {
    final qr = payload.trim();
    final LankaQr code;
    try {
      code = LankaQr.parse(qr);
    } on LankaQrException catch (exception) {
      return Err(Failure(exception.issue == LankaQrIssue.currency ? FailureCodes.unsupportedCurrency : FailureCodes.invalidQr));
    }
    if (!code.isPersonal) return guardApi(() async => (await _remote.lookupMerchant(qr)).toEntity(qr));
    final phone = PhoneNumber.tryParse(code.accountId);
    if (phone == null) return const Err(Failure(FailureCodes.invalidQr));
    return guardApi(() async => ScannedCode(amount: code.amount, recipient: PersonRecipient((await _remote.lookupPayee(phone.e164)).toEntity())));
  }

  @override
  Future<Result<PaymentReceipt>> sendPayment(PaymentDraft draft, Authorization authorization) => guardApi(() async {
    final receipt = switch (draft.recipient) {
      PersonRecipient(:final payee) => await _sendTransfer(draft, payee, authorization),
      final MerchantRecipient recipient => await _payMerchant(draft, recipient, authorization),
      final BillRecipient recipient => await _payBill(draft, recipient, authorization),
      final ReloadRecipient recipient => await _reload(draft, recipient, authorization),
      final BankRecipient recipient => await _sendToBank(draft, recipient, authorization),
      final TopUpRecipient recipient => await _topUp(draft, recipient, authorization),
      final WithdrawalRecipient recipient => await _withdraw(draft, recipient, authorization),
    };
    _events.publish(const WalletChanged());
    return receipt;
  });
}
