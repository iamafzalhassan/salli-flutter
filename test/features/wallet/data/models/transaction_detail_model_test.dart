import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/payments/domain/entities/recipient.dart';
import 'package:salli/features/wallet/data/models/transaction_detail_model.dart';
import 'package:salli/features/wallet/domain/entities/dispute_reason.dart';
import 'package:salli/features/wallet/domain/entities/timeline_status.dart';
import 'package:salli/features/wallet/domain/entities/transaction_type.dart';

void main() {
  Map<String, dynamic> payload({Map<String, dynamic>? repeat, Map<String, dynamic>? dispute}) => {
    'amountCents': -150000,
    'counterpartyName': 'Kavindi Silva',
    'counterpartyPhone': '+94771112233',
    'createdAt': '2026-09-21T09:00:00.000Z',
    'dispute': dispute,
    'feeCents': 0,
    'id': 'txn-1',
    'note': 'Lunch',
    'reference': 'SAL12345678',
    'repeat': repeat,
    'status': 'completed',
    'timeline': [
      {'at': '2026-09-21T09:00:00.000Z', 'status': 'initiated'},
      {'at': '2026-09-21T09:00:02.000Z', 'status': 'completed'},
    ],
    'type': 'transfer_out',
  };

  test('maps the transaction, its timeline and a transfer to repeat', () {
    final detail = TransactionDetailModel.fromJson(payload(repeat: {'kind': 'transfer', 'name': 'Kavindi Silva', 'phone': '+94771112233'})).toEntity();
    expect(detail.transaction.type, TransactionType.transferOut);
    expect(detail.transaction.amount, const Money(-150000));
    expect(detail.timeline.map((step) => step.status), [TimelineStatus.initiated, TimelineStatus.completed]);
    final repeat = detail.repeatRecipient;
    expect(repeat, isA<PersonRecipient>());
    expect((repeat! as PersonRecipient).payee.phone.e164, '+94771112233');
  });

  test('maps a bank transfer to repeat with its fee', () {
    final detail = TransactionDetailModel.fromJson(
      payload(repeat: {'accountName': 'K SILVA', 'accountNumber': '0012345678', 'bankCode': '7010', 'bankName': 'Bank of Ceylon', 'bankShortName': 'BOC', 'branchCode': null, 'feeCents': 2500, 'kind': 'bank'}),
    ).toEntity();
    final repeat = detail.repeatRecipient;
    expect(repeat, isA<BankRecipient>());
    expect(repeat!.fee, const Money(2500));
  });

  test('has nothing to repeat for an unknown kind or money received', () {
    expect(TransactionDetailModel.fromJson(payload(repeat: {'kind': 'bonus'})).toEntity().repeatRecipient, isNull);
    expect(TransactionDetailModel.fromJson(payload()).toEntity().repeatRecipient, isNull);
  });

  test('maps an open dispute', () {
    final detail = TransactionDetailModel.fromJson(payload(dispute: {'createdAt': '2026-09-21T10:00:00.000Z', 'id': 'dispute-1', 'reason': 'not_received', 'reference': 'DSP12345678', 'status': 'open'})).toEntity();
    expect(detail.dispute?.reason, DisputeReason.notReceived);
    expect(detail.dispute?.reference, 'DSP12345678');
  });
}
