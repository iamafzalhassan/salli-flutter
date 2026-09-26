import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import 'notification_kind.dart';

class AppNotification extends Equatable {
  final bool isRead;

  final String id;

  final String? name;
  final String? transactionId;

  final DateTime createdAt;

  final Money? amount;

  final NotificationKind kind;

  const AppNotification({required this.isRead, required this.id, this.name, this.transactionId, required this.createdAt, this.amount, required this.kind});

  AppNotification markedRead() => AppNotification(amount: amount, createdAt: createdAt, id: id, isRead: true, kind: kind, name: name, transactionId: transactionId);

  @override
  List<Object?> get props => [isRead, id, name, transactionId, createdAt, amount, kind];
}
