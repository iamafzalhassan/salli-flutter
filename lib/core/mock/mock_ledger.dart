import 'dart:math';

import '../utils/id_generator.dart';
import 'mock_collections.dart';
import 'mock_store.dart';

class MockLedger {
  static const int referenceDigits = 10;

  static const String completed = 'completed';
  static const String referencePrefix = 'SAL';

  final MockStore _store;

  final Random _random = Random.secure();

  MockLedger(this._store);

  int balanceOf(String account) => _store.all(MockCollections.ledgerEntries).where((entry) => entry['account'] == account).fold(0, (sum, entry) => sum + (entry['amountCents'] as int));

  String nextReference() => '$referencePrefix${[for (var index = 0; index < referenceDigits; index++) _random.nextInt(10)].join()}';

  int outgoingSince(String account, DateTime since) =>
      transactionsFor(account).where((transaction) => transaction['debitAccount'] == account && !DateTime.parse(transaction['createdAt'] as String).isBefore(since)).fold(0, (sum, transaction) => sum + (transaction['amountCents'] as int));

  Future<Map<String, dynamic>> post({
    required int amountCents,
    required DateTime at,
    required String creditAccount,
    required String creditName,
    String? creditPhone,
    required String debitAccount,
    required String debitName,
    String? debitPhone,
    int feeCents = 0,
    Map<String, dynamic> meta = const {},
    String? note,
    String? reference,
    required String type,
  }) async {
    if (amountCents <= 0) throw ArgumentError.value(amountCents, 'amountCents', 'Must be positive');
    final id = IdGenerator.next();
    final transaction = {
      'amountCents': amountCents,
      'creditAccount': creditAccount,
      'creditName': creditName,
      'creditPhone': creditPhone,
      'debitAccount': debitAccount,
      'debitName': debitName,
      'debitPhone': debitPhone,
      'feeCents': feeCents,
      'id': id,
      'meta': meta,
      'note': note,
      'reference': reference,
      'status': completed,
      'type': type,
      'createdAt': at.toUtc().toIso8601String(),
    };
    await _store.put(MockCollections.ledgerTransactions, id, transaction);
    await _store.put(MockCollections.ledgerEntries, '$id:debit', {'account': debitAccount, 'amountCents': -amountCents, 'transactionId': id});
    await _store.put(MockCollections.ledgerEntries, '$id:credit', {'account': creditAccount, 'amountCents': amountCents, 'transactionId': id});
    return transaction;
  }

  List<Map<String, dynamic>> transactionsFor(String account) =>
      _store.all(MockCollections.ledgerTransactions).where((transaction) => transaction['debitAccount'] == account || transaction['creditAccount'] == account).toList()
        ..sort((first, second) => (second['createdAt'] as String).compareTo(first['createdAt'] as String));
}
