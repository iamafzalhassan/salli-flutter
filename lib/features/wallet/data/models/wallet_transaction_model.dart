import '../../../../core/utils/money.dart';
import '../../domain/entities/transaction_status.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel {
  static const Map<String, TransactionStatus> _statuses = {'completed': TransactionStatus.completed, 'failed': TransactionStatus.failed, 'pending': TransactionStatus.pending};

  static const Map<String, TransactionType> _types = {
    'bank_transfer': TransactionType.bankTransfer,
    'bill': TransactionType.bill,
    'bonus': TransactionType.bonus,
    'card': TransactionType.card,
    'cashback': TransactionType.cashback,
    'fee': TransactionType.fee,
    'merchant': TransactionType.merchant,
    'reload': TransactionType.reload,
    'top_up': TransactionType.topUp,
    'transfer_in': TransactionType.transferIn,
    'transfer_out': TransactionType.transferOut,
    'withdrawal': TransactionType.withdrawal,
  };

  static final Map<TransactionType, String> apiNames = _types.map((name, type) => MapEntry(type, name));

  final int amountCents;

  final String counterpartyName;
  final String id;
  final String status;
  final String type;

  final DateTime createdAt;

  const WalletTransactionModel({required this.amountCents, required this.counterpartyName, required this.id, required this.status, required this.type, required this.createdAt});

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) => WalletTransactionModel(
    amountCents: json['amountCents'] as int,
    counterpartyName: json['counterpartyName'] as String,
    id: json['id'] as String,
    status: json['status'] as String,
    type: json['type'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  WalletTransaction toEntity() =>
      WalletTransaction(amount: Money(amountCents), counterpartyName: counterpartyName, createdAt: createdAt, id: id, status: _statuses[status] ?? TransactionStatus.pending, type: _types[type] ?? TransactionType.other);
}
