import '../../domain/entities/transaction_page.dart';
import 'wallet_transaction_model.dart';

class TransactionPageModel {
  final String? nextCursor;

  final List<WalletTransactionModel> items;

  const TransactionPageModel({this.nextCursor, required this.items});

  factory TransactionPageModel.fromJson(Map<String, dynamic> json) =>
      TransactionPageModel(nextCursor: json['nextCursor'] as String?, items: [for (final item in json['items'] as List<dynamic>) WalletTransactionModel.fromJson(item as Map<String, dynamic>)]);

  TransactionPage toEntity() => TransactionPage(items: [for (final item in items) item.toEntity()], nextCursor: nextCursor);
}
