import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/wallet/data/models/transaction_filter_model.dart';
import 'package:salli/features/wallet/domain/entities/transaction_filter.dart';
import 'package:salli/features/wallet/domain/entities/transaction_type.dart';

void main() {
  test('an empty filter adds nothing to the query', () {
    expect(const TransactionFilterModel(TransactionFilter(query: '  ')).toQuery(), isEmpty);
  });

  test('sends API type names, UTC dates and amounts in cents', () {
    final filter = TransactionFilter(
      from: DateTime.utc(2026, 9),
      max: const Money.rupees(10000),
      min: const Money.rupees(1000),
      query: ' pick ',
      to: DateTime.utc(2026, 10),
      types: const {TransactionType.transferOut, TransactionType.bankTransfer},
    );
    expect(TransactionFilterModel(filter).toQuery(), {'from': '2026-09-01T00:00:00.000Z', 'maxCents': 1000000, 'minCents': 100000, 'q': 'pick', 'to': '2026-10-01T00:00:00.000Z', 'type': 'bank_transfer,transfer_out'});
  });
}
