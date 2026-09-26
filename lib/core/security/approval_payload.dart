import 'dart:convert';

abstract final class ApprovalPayload {
  static List<int> bankTransfer({required String accountNumber, required int amountCents, required String bankCode, required String idempotencyKey}) => _encode(['bank_transfer', idempotencyKey, bankCode, accountNumber, '$amountCents']);

  static List<int> billMandate({required int dayOfMonth, required String idempotencyKey, required String savedBillerId}) => _encode(['bill_mandate', idempotencyKey, savedBillerId, '$dayOfMonth']);

  static List<int> billPayment({required String accountNumber, required int amountCents, required String billerId, required String idempotencyKey}) => _encode(['bill_payment', idempotencyKey, billerId, accountNumber, '$amountCents']);

  static List<int> cardReveal({required String cardId, required String nonce, required String timestamp}) => _encode(['card_reveal', cardId, nonce, timestamp]);

  static List<int> merchantPayment({required int amountCents, required String idempotencyKey, required String merchantId}) => _encode(['merchant_payment', idempotencyKey, merchantId, '$amountCents']);

  static List<int> reload({required int amountCents, required String idempotencyKey, required String phone, String? planId}) => _encode(['reload', idempotencyKey, phone, planId ?? '', '$amountCents']);

  static List<int> topUp({required int amountCents, required String idempotencyKey, required String sourceId}) => _encode(['top_up', idempotencyKey, sourceId, '$amountCents']);

  static List<int> transfer({required int amountCents, required String idempotencyKey, required String recipientPhone}) => _encode(['transfer', idempotencyKey, recipientPhone, '$amountCents']);

  static List<int> unlock({required String nonce, required String timestamp}) => _encode(['unlock', nonce, timestamp]);

  static List<int> withdrawal({required int amountCents, required String idempotencyKey, required String sourceId}) => _encode(['withdrawal', idempotencyKey, sourceId, '$amountCents']);

  static List<int> _encode(List<String> lines) => utf8.encode(lines.join('\n'));
}
