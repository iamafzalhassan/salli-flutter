import '../../domain/entities/transaction_filter.dart';
import 'wallet_transaction_model.dart';

class TransactionFilterModel {
  final TransactionFilter filter;

  const TransactionFilterModel(this.filter);

  Map<String, Object> toQuery() {
    final query = filter.query.trim();
    final types = [for (final type in filter.types) ?WalletTransactionModel.apiNames[type]]..sort();
    return {
      if (query.isNotEmpty) 'q': query,
      if (types.isNotEmpty) 'type': types.join(','),
      'from': ?filter.from?.toUtc().toIso8601String(),
      'to': ?filter.to?.toUtc().toIso8601String(),
      'maxCents': ?filter.max?.cents,
      'minCents': ?filter.min?.cents,
    };
  }
}
