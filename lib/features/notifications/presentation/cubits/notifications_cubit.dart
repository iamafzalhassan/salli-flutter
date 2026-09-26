import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import '../../domain/usecases/mark_notification_read.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotifications _getNotifications;

  final MarkAllNotificationsRead _markAllRead;

  final MarkNotificationRead _markRead;

  NotificationsCubit(this._getNotifications, this._markAllRead, this._markRead) : super(const NotificationsState());

  Future<void> load() async {
    if (state.items.isEmpty) emit(const NotificationsState());
    final result = await _getNotifications();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => NotificationsState(items: value, status: NotificationsStatus.ready),
      Err(:final failure) => NotificationsState(failure: failure, items: state.items, status: state.items.isEmpty ? NotificationsStatus.failure : NotificationsStatus.ready),
    });
  }

  Future<void> markAllRead() async {
    if (!state.hasUnread) return;
    emit(NotificationsState(items: [for (final item in state.items) item.markedRead()], status: state.status));
    await _markAllRead();
  }

  Future<void> open(AppNotification notification) async {
    if (notification.isRead) return;
    emit(NotificationsState(items: [for (final item in state.items) item.id == notification.id ? item.markedRead() : item], status: state.status));
    await _markRead(notification.id);
  }
}
