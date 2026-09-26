import '../../../../core/utils/money.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../payments/domain/entities/bill_category.dart';
import '../../../payments/domain/entities/merchant.dart';
import '../../../payments/domain/entities/merchant_category.dart';
import '../../../payments/domain/entities/payee.dart';
import '../../../payments/domain/entities/recipient.dart';
import '../../domain/entities/timeline_status.dart';
import '../../domain/entities/timeline_step.dart';
import '../../domain/entities/transaction_detail.dart';
import 'dispute_model.dart';
import 'wallet_transaction_model.dart';

class TransactionDetailModel {
  static const Map<String, TimelineStatus> _statuses = {'completed': TimelineStatus.completed, 'failed': TimelineStatus.failed, 'initiated': TimelineStatus.initiated, 'pending': TimelineStatus.pending};

  final int feeCents;

  final String? counterpartyPhone;
  final String? note;
  final String? reference;

  final List<({String at, String status})> timeline;

  final Map<String, dynamic>? repeat;

  final DisputeModel? dispute;

  final WalletTransactionModel transaction;

  const TransactionDetailModel({required this.feeCents, this.counterpartyPhone, this.note, this.reference, required this.timeline, this.repeat, this.dispute, required this.transaction});

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) => TransactionDetailModel(
    feeCents: json['feeCents'] as int? ?? 0,
    counterpartyPhone: json['counterpartyPhone'] as String?,
    note: json['note'] as String?,
    reference: json['reference'] as String?,
    timeline: [for (final step in (json['timeline'] as List<dynamic>).cast<Map<String, dynamic>>()) (at: step['at'] as String, status: step['status'] as String)],
    repeat: json['repeat'] as Map<String, dynamic>?,
    dispute: json['dispute'] == null ? null : DisputeModel.fromJson(json['dispute'] as Map<String, dynamic>),
    transaction: WalletTransactionModel.fromJson(json),
  );

  TransactionDetail toEntity() => TransactionDetail(
    counterpartyPhone: counterpartyPhone,
    dispute: dispute?.toEntity(),
    fee: Money(feeCents),
    note: note,
    reference: reference,
    repeatRecipient: _recipient(repeat),
    timeline: [for (final step in timeline) TimelineStep(at: DateTime.parse(step.at), status: _statuses[step.status] ?? TimelineStatus.pending)],
    transaction: transaction.toEntity(),
  );

  Recipient? _recipient(Map<String, dynamic>? repeat) {
    if (repeat == null) return null;
    final phone = PhoneNumber.tryParse(repeat['phone'] as String? ?? '');
    final merchant = repeat['merchant'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return switch (repeat['kind']) {
      'transfer' when phone != null => PersonRecipient(Payee(name: repeat['name'] as String?, phone: phone)),
      'reload' when phone != null => ReloadRecipient(phone: phone),
      'merchant' => MerchantRecipient(
        merchant: Merchant(category: MerchantCategory.values.asNameMap()[merchant['category']] ?? MerchantCategory.other, city: merchant['city'] as String, id: merchant['id'] as String, name: merchant['name'] as String),
        qr: repeat['qr'] as String,
      ),
      'bill' => BillRecipient(
        accountNumber: repeat['accountNumber'] as String,
        billerId: repeat['billerId'] as String,
        billerName: repeat['billerName'] as String,
        category: BillCategory.values.asNameMap()[repeat['category']] ?? BillCategory.other,
      ),
      'bank' => BankRecipient(
        accountName: repeat['accountName'] as String,
        accountNumber: repeat['accountNumber'] as String,
        bankCode: repeat['bankCode'] as String,
        bankName: repeat['bankName'] as String,
        bankShortName: repeat['bankShortName'] as String,
        branchCode: repeat['branchCode'] as String?,
        fee: Money(repeat['feeCents'] as int),
      ),
      _ => null,
    };
  }
}
