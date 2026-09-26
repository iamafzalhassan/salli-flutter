import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/utils/money.dart';
import 'package:salli/features/notifications/data/models/app_notification_model.dart';
import 'package:salli/features/notifications/domain/entities/notification_kind.dart';

void main() {
  test('maps a money notification and its params', () {
    final notification = AppNotificationModel.fromJson({
      'createdAt': '2026-09-21T09:00:00.000Z',
      'id': 'n-1',
      'isRead': false,
      'kind': 'money_received',
      'params': {'amountCents': 50000, 'name': 'Nimal Perera', 'transactionId': 'txn-1'},
    }).toEntity();
    expect(notification.kind, NotificationKind.moneyReceived);
    expect(notification.amount, const Money(50000));
    expect(notification.name, 'Nimal Perera');
    expect(notification.transactionId, 'txn-1');
  });

  test('takes a merchant as the name and keeps an unknown kind readable', () {
    final cashback = AppNotificationModel.fromJson({
      'createdAt': '2026-09-21T09:00:00.000Z',
      'id': 'n-2',
      'isRead': true,
      'kind': 'cashback_earned',
      'params': {'amountCents': 15000, 'merchant': 'Java Lounge'},
    }).toEntity();
    expect(cashback.name, 'Java Lounge');
    final unknown = AppNotificationModel.fromJson({'createdAt': '2026-09-21T09:00:00.000Z', 'id': 'n-3', 'kind': 'future_kind'}).toEntity();
    expect(unknown.kind, NotificationKind.other);
    expect(unknown.amount, isNull);
  });
}
