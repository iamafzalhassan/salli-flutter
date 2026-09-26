import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/recipient.dart';
import '../../domain/entities/step_up_reason.dart';

class RiskRequestModel {
  static const Map<String, StepUpReason> _reasons = {'large_amount': StepUpReason.largeAmount, 'new_device': StepUpReason.newDevice, 'new_payee': StepUpReason.newPayee};

  final PaymentDraft draft;

  const RiskRequestModel(this.draft);

  static Set<StepUpReason> reasonsFrom(Map<String, dynamic> json) => {for (final reason in (json['reasons'] as List<dynamic>).cast<String>()) ?_reasons[reason]};

  Map<String, dynamic> toJson() => {
    'amountCents': draft.amount.cents,
    ...switch (draft.recipient) {
      PersonRecipient(:final payee) => {'recipientPhone': payee.phone.e164, 'type': 'transfer'},
      BankRecipient(:final accountNumber, :final bankCode) => {'accountNumber': accountNumber, 'bankCode': bankCode, 'type': 'bank_transfer'},
      MerchantRecipient() => {'type': 'merchant'},
      BillRecipient() => {'type': 'bill'},
      ReloadRecipient() => {'type': 'reload'},
      TopUpRecipient() => {'type': 'top_up'},
      WithdrawalRecipient() => {'type': 'withdrawal'},
    },
  };
}
