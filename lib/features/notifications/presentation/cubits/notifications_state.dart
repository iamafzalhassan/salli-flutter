import 'package:equatable/equatable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_notification.dart';

enum NotificationsStatus { failure, loading, ready }

class NotificationsState extends Equatable {
  final List<AppNotification> items;

  final Failure? failure;

  final NotificationsStatus status;

  const NotificationsState({this.items = const [], this.failure, this.status = NotificationsStatus.loading});

  bool get hasUnread => items.any((item) => !item.isRead);

  @override
  List<Object?> get props => [items, failure, status];
}
